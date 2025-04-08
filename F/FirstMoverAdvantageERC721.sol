// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FirstMoverAdvantageERC721
 * @dev ERC721 token that awards a bonus NFT to the first caller.
 * The bonus NFT can only be claimed once.
 */
contract FirstMoverAdvantageERC721 is ERC721Enumerable, Ownable {
    bool public bonusClaimed;
    uint256 private constant BONUS_TOKEN_ID = 1; // Bonus NFT token ID

    event BonusNFTClaimed(address indexed claimer, uint256 tokenId);

    /**
     * @dev Constructor sets the token name, symbol, and owner.
     */
    constructor() ERC721("FirstMoverAdvantageERC721", "FMA721") Ownable(msg.sender) {
        bonusClaimed = false;
    }

    /**
     * @dev Allows the first caller to claim the bonus NFT.
     */
    function claimBonusNFT() external {
        require(!bonusClaimed, "Bonus NFT already claimed");
        require(ownerOf(BONUS_TOKEN_ID) == address(0), "Bonus token already minted");
        bonusClaimed = true;
        _safeMint(msg.sender, BONUS_TOKEN_ID);
        emit BonusNFTClaimed(msg.sender, BONUS_TOKEN_ID);
    }
}
