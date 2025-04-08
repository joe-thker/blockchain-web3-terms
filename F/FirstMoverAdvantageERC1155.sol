// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FirstMoverAdvantageERC1155
 * @dev ERC1155 token that awards a bonus token to the first caller.
 * The bonus token is of a specific ID and can only be claimed once.
 */
contract FirstMoverAdvantageERC1155 is ERC1155, Ownable {
    bool public bonusClaimed;
    uint256 public constant BONUS_TOKEN_ID = 1;
    uint256 public bonusTokenAmount;

    event BonusTokenClaimed(address indexed claimer, uint256 tokenId, uint256 amount);
    event BonusTokenAmountUpdated(uint256 newAmount);

    /**
     * @dev Constructor sets the bonus token amount and base URI.
     * @param _bonusTokenAmount The bonus amount for the token of id BONUS_TOKEN_ID.
     * @param uri_ The base URI for token metadata.
     */
    constructor(uint256 _bonusTokenAmount, string memory uri_)
        ERC1155(uri_)
        Ownable(msg.sender)
    {
        bonusClaimed = false;
        bonusTokenAmount = _bonusTokenAmount;
    }

    /**
     * @dev Allows the owner to update the bonus token amount.
     * @param _bonusTokenAmount New bonus token amount.
     */
    function setBonusTokenAmount(uint256 _bonusTokenAmount) external onlyOwner {
        bonusTokenAmount = _bonusTokenAmount;
        emit BonusTokenAmountUpdated(_bonusTokenAmount);
    }

    /**
     * @dev Allows the first caller to claim the bonus token.
     */
    function claimBonusToken() external {
        require(!bonusClaimed, "Bonus token already claimed");
        require(bonusTokenAmount > 0, "Bonus token amount not set");
        bonusClaimed = true;
        _mint(msg.sender, BONUS_TOKEN_ID, bonusTokenAmount, "");
        emit BonusTokenClaimed(msg.sender, BONUS_TOKEN_ID, bonusTokenAmount);
    }
}
