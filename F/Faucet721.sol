// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC721Faucet
 * @dev An NFT faucet that mints a free NFT to users, with a cooldown between claims.
 */
contract ERC721Faucet is ERC721Enumerable, Ownable {
    // Cooldown time (in seconds) between NFT claims.
    uint256 public cooldownTime;
    // Tracks last claim time for each address.
    mapping(address => uint256) public lastClaimed;
    // Token ID counter.
    uint256 private _nextTokenId;

    event NFTClaimed(address indexed user, uint256 tokenId);
    event CooldownTimeUpdated(uint256 newCooldownTime);

    /**
     * @dev Constructor sets the NFT name, symbol, and cooldown time.
     * @param _cooldownTime Cooldown time in seconds between claims.
     */
    constructor(uint256 _cooldownTime)
        ERC721("ERC721 Faucet NFT", "FNFT")
        Ownable(msg.sender)
    {
        cooldownTime = _cooldownTime;
        _nextTokenId = 1;
    }

    /**
     * @dev Allows a user to claim an NFT.
     */
    function claim() external {
        require(block.timestamp - lastClaimed[msg.sender] >= cooldownTime, "Wait before claiming again");
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        lastClaimed[msg.sender] = block.timestamp;
        _safeMint(msg.sender, tokenId);
        emit NFTClaimed(msg.sender, tokenId);
    }

    /**
     * @dev Allows the owner to update the cooldown time.
     */
    function setCooldownTime(uint256 _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
        emit CooldownTimeUpdated(_cooldownTime);
    }
}
