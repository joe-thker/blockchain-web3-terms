// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Interface for borrower contracts to implement.
 */
interface IFlashLoanBorrower {
    function executeOnFlashLoan(uint256 amount, uint256 fee) external;
}

/**
 * @title FlashLoanWithFeeSplit
 * @dev Flash loan provider with fee split logic between the treasury and contract.
 */
contract FlashLoanWithFeeSplit is Ownable {
    IERC20 public token;
    address public treasury;

    uint256 public feeBps = 10; // 0.10%
    uint256 public treasuryShare = 50; // 50%

    constructor(address _token, address _treasury) Ownable(msg.sender) {
        require(_token != address(0), "Invalid token");
        require(_treasury != address(0), "Invalid treasury");
        token = IERC20(_token);
        treasury = _treasury;
    }

    /**
     * @notice Executes a flash loan to the borrower (msg.sender).
     * Borrower must implement `executeOnFlashLoan(amount, fee)` and return the funds + fee in one transaction.
     */
    function executeFlashLoan(uint256 amount) external {
        uint256 fee = (amount * feeBps) / 10000;
        uint256 totalDue = amount + fee;

        uint256 beforeBalance = token.balanceOf(address(this));
        require(beforeBalance >= amount, "Not enough liquidity");

        // Transfer the loan
        token.transfer(msg.sender, amount);

        // Call the borrower's callback
        IFlashLoanBorrower(msg.sender).executeOnFlashLoan(amount, fee);

        // Require repayment
        uint256 afterBalance = token.balanceOf(address(this));
        require(afterBalance >= beforeBalance + fee, "Loan not repaid with fee");

        // Distribute fee
        uint256 treasuryAmount = (fee * treasuryShare) / 100;
        token.transfer(treasury, treasuryAmount);
        // Remaining fee stays in the contract
    }

    /**
     * @notice Update fee and share settings.
     */
    function updateSettings(uint256 _feeBps, uint256 _treasuryShare) external onlyOwner {
        require(_feeBps <= 100, "Fee too high");
        require(_treasuryShare <= 100, "Share too high");
        feeBps = _feeBps;
        treasuryShare = _treasuryShare;
    }

    /**
     * @notice Allows the owner to withdraw tokens.
     */
    function withdraw(address to, uint256 amount) external onlyOwner {
        token.transfer(to, amount);
    }
}
