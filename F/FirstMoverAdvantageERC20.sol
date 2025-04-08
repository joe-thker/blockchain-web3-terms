// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FirstMoverAdvantageERC20
 * @dev ERC20 token that rewards the first caller with a bonus amount of tokens.
 * Once the bonus is claimed, it cannot be claimed again.
 */
contract FirstMoverAdvantageERC20 is ERC20, Ownable {
    bool public bonusClaimed;
    uint256 public bonusAmount;

    event BonusClaimed(address indexed claimer, uint256 amount);
    event BonusAmountUpdated(uint256 newBonusAmount);

    /**
     * @dev Constructor that mints the initial supply to the deployer and sets the bonus amount.
     * @param initialSupply Total initial supply in the smallest unit.
     * @param _bonusAmount Bonus token amount to be granted to the first mover.
     */
    constructor(uint256 initialSupply, uint256 _bonusAmount)
        ERC20("FirstMoverAdvantageERC20", "FMA20")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
        bonusAmount = _bonusAmount;
    }

    /**
     * @dev Allows the owner to update the bonus amount.
     * @param _bonusAmount New bonus amount.
     */
    function setBonusAmount(uint256 _bonusAmount) external onlyOwner {
        bonusAmount = _bonusAmount;
        emit BonusAmountUpdated(_bonusAmount);
    }

    /**
     * @dev Claims the bonus. The first caller receives the bonus tokens.
     */
    function claimBonus() external {
        require(!bonusClaimed, "Bonus already claimed");
        bonusClaimed = true;
        _mint(msg.sender, bonusAmount);
        emit BonusClaimed(msg.sender, bonusAmount);
    }
}
