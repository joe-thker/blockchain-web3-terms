// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FlashLoanProvider
 * @dev Offers basic flash loans using an ERC20 token.
 *      The borrower must implement `executeOnFlashLoan()` and repay the loan + fee in the same transaction.
 */
contract FlashLoanProvider is Ownable {
    IERC20 public token;
    uint256 public feeBasisPoints = 5; // 0.05% fee (5 BPS)

    event FlashLoanExecuted(address borrower, uint256 amount, uint256 fee);

    constructor(address _token) Ownable(msg.sender) {
        require(_token != address(0), "Invalid token");
        token = IERC20(_token);
    }

    /**
     * @notice Allows a borrower to take out a flash loan.
     * @param amount The amount to borrow.
     */
    function executeFlashLoan(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient liquidity");

        // Calculate fee
        uint256 fee = (amount * feeBasisPoints) / 10000;

        // Transfer loan to borrower
        token.transfer(msg.sender, amount);

        // Callback to borrower
        IFlashLoanBorrower(msg.sender).executeOnFlashLoan(amount, fee);

        // Require repayment
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore + fee, "Flash loan not repaid");

        emit FlashLoanExecuted(msg.sender, amount, fee);
    }

    /**
     * @notice Owner can withdraw fees or unused tokens.
     */
    function withdraw(address to, uint256 amount) external onlyOwner {
        token.transfer(to, amount);
    }

    function updateFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 100, "Too high");
        feeBasisPoints = newFeeBps;
    }
}

/**
 * @dev Interface for contracts that use FlashLoanProvider.
 */
interface IFlashLoanBorrower {
    function executeOnFlashLoan(uint256 amount, uint256 fee) external;
}
