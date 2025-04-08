// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FirstMoverAdvantage
 * @dev This contract implements a First-Mover Advantage mechanism. The contract holds an ETH bonus.
 * The first address to call claimBonus() gets the bonus, which cannot be claimed more than once.
 * The owner can set the bonus amount and withdraw remaining funds.
 */
contract FirstMoverAdvantage is Ownable {
    // Indicates whether the bonus has been claimed
    bool public bonusClaimed;
    // Bonus amount in wei
    uint256 public bonusAmount;

    event BonusClaimed(address indexed claimer, uint256 amount);
    event BonusAmountUpdated(uint256 newBonusAmount);

    /**
     * @dev Constructor sets the deployer as the owner (inherited from Ownable).
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Allows the owner to set the bonus amount.
     * @param newBonusAmount The bonus amount in wei.
     */
    function setBonusAmount(uint256 newBonusAmount) external onlyOwner {
        bonusAmount = newBonusAmount;
        emit BonusAmountUpdated(newBonusAmount);
    }

    /**
     * @notice Claim the bonus. The first caller receives the bonus and bonusClaimed is set to true.
     */
    function claimBonus() external {
        require(!bonusClaimed, "Bonus already claimed");
        require(address(this).balance >= bonusAmount, "Insufficient bonus funds");
        
        bonusClaimed = true;
        payable(msg.sender).transfer(bonusAmount);
        emit BonusClaimed(msg.sender, bonusAmount);
    }

    /**
     * @notice Allows the owner to withdraw ETH from the contract.
     * @param amount The amount in wei to withdraw.
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    /**
     * @notice Fallback function to accept ETH deposits.
     */
    receive() external payable {}
}
