// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FiatOnRampERC1155
 * @dev ERC1155 token that acts as a fiat on-ramp.
 * Different token IDs represent different fiat-backed assets or voucher types.
 * Users deposit ETH to receive tokens based on a conversion rate set per token ID.
 */
contract FiatOnRampERC1155 is ERC1155, Ownable {
    // Mapping from token ID to conversion rate (number of tokens minted per 1 ETH).
    mapping(uint256 => uint256) public tokensPerEth;
    // Event emitted when a deposit is made.
    event Deposited(address indexed user, uint256 tokenId, uint256 ethAmount, uint256 tokenAmount);

    /**
     * @dev Constructor sets the base URI.
     * @param uri_ Base URI for token metadata.
     */
    constructor(string memory uri_) ERC1155(uri_) Ownable(msg.sender) {}

    /**
     * @dev Sets the conversion rate for a given token ID.
     * @param tokenId The token ID.
     * @param rate Conversion rate (tokens per 1 ETH), using 18 decimals.
     */
    function setTokensPerEth(uint256 tokenId, uint256 rate) external onlyOwner {
        require(rate > 0, "Rate must be > 0");
        tokensPerEth[tokenId] = rate;
    }

    /**
     * @dev Deposit ETH to receive tokens of a specified token ID.
     * @param tokenId The token ID to claim.
     */
    function deposit(uint256 tokenId) external payable {
        require(msg.value > 0, "Must send ETH");
        uint256 rate = tokensPerEth[tokenId];
        require(rate > 0, "Conversion rate not set for token");
        uint256 tokenAmount = (msg.value * rate) / 1 ether;
        _mint(msg.sender, tokenId, tokenAmount, "");
        emit Deposited(msg.sender, tokenId, msg.value, tokenAmount);
    }

    /**
     * @dev Allows the owner to withdraw ETH from the contract.
     * @param amount Amount of ETH (in wei) to withdraw.
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    /**
     * @dev Fallback function to accept ETH.
     */
    receive() external payable {}
}
