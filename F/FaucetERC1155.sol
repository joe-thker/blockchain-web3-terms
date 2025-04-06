// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC1155Faucet
 * @dev An ERC1155 faucet that allows users to claim tokens for a specific token ID after a cooldown.
 */
contract ERC1155Faucet is ERC1155, Ownable {
    // Global cooldown time in seconds.
    uint256 public cooldownTime;
    // Mapping from (user, tokenId) to last claim timestamp.
    mapping(address => mapping(uint256 => uint256)) public lastClaimed;
    // Claim amount per token ID.
    mapping(uint256 => uint256) public claimAmounts;

    event Claimed(address indexed user, uint256 indexed tokenId, uint256 amount);
    event ClaimAmountUpdated(uint256 indexed tokenId, uint256 newClaimAmount);
    event CooldownTimeUpdated(uint256 newCooldownTime);

    /**
     * @dev Constructor sets the base URI and initial cooldown time.
     * @param uri_ Base URI for token metadata.
     * @param _cooldownTime Cooldown time in seconds between claims.
     */
    constructor(string memory uri_, uint256 _cooldownTime)
        ERC1155(uri_)
        Ownable(msg.sender)
    {
        cooldownTime = _cooldownTime;
    }

    /**
     * @dev Allows the owner to set the claim amount for a specific token ID.
     */
    function setClaimAmount(uint256 tokenId, uint256 amount) external onlyOwner {
        claimAmounts[tokenId] = amount;
        emit ClaimAmountUpdated(tokenId, amount);
    }

    /**
     * @dev Allows the owner to update the global cooldown time.
     */
    function setCooldownTime(uint256 _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
        emit CooldownTimeUpdated(_cooldownTime);
    }

    /**
     * @dev Allows a user to claim tokens of a given token ID.
     */
    function claim(uint256 tokenId) external {
        require(block.timestamp - lastClaimed[msg.sender][tokenId] >= cooldownTime, "Wait before claiming again");
        uint256 amount = claimAmounts[tokenId];
        require(balanceOf(address(this), tokenId) >= amount, "Faucet empty for token");
        lastClaimed[msg.sender][tokenId] = block.timestamp;
        safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        emit Claimed(msg.sender, tokenId, amount);
    }

    /**
     * @dev Allows the owner to withdraw tokens of a specific token ID.
     */
    function withdraw(uint256 tokenId, uint256 amount) external onlyOwner {
        safeTransferFrom(address(this), owner(), tokenId, amount, "");
    }
}
