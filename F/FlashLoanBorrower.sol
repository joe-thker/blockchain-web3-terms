// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IFlashLoanProvider {
    function executeFlashLoan(uint256 amount) external;
}

/**
 * @title FlashLoanBorrower
 * @dev This contract takes a flash loan and repays it with a fee in the same transaction.
 */
contract FlashLoanBorrower {
    address public token;
    address public loanProvider;

    constructor(address _loanProvider, address _token) {
        loanProvider = _loanProvider;
        token = _token;
    }

    /**
     * @notice Initiates the flash loan process
     */
    function initiateFlashLoan(uint256 amount) external {
        IFlashLoanProvider(loanProvider).executeFlashLoan(amount);
    }

    /**
     * @dev Called by the flash loan provider during the loan process.
     */
    function executeOnFlashLoan(uint256 amount, uint256 fee) external {
        require(msg.sender == loanProvider, "Unauthorized");

        // Do your logic here (arbitrage, liquidation, etc.)

        // Repay loan + fee
        uint256 repayment = amount + fee;
        IERC20(token).transfer(loanProvider, repayment);
    }
}
