// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FairAIMultiToken
 * @dev ERC1155 Token Contract for managing multiple token types with individual mint fees.
 */
contract FairAIMultiToken is ERC1155, Ownable {
    // Mapping from token ID to mint fee
    mapping(uint256 => uint256) public mintFees;
    // Address that receives mint fees
    address public feeRecipient;
    // Mapping to track total supply for each token type
    mapping(uint256 => uint256) public totalSupply;

    event MintFeeUpdated(uint256 tokenId, uint256 newMintFee);
    event FeeRecipientUpdated(address newFeeRecipient);

    /**
     * @dev Constructor sets the base URI and fee recipient.
     * @param uri Base URI for token metadata.
     * @param _feeRecipient Address that will receive the mint fees.
     */
    constructor(string memory uri, address _feeRecipient) ERC1155(uri) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Owner can set the mint fee for a specific token type.
     * @param tokenId The token type identifier.
     * @param fee Mint fee for each token of this type.
     */
    function setMintFee(uint256 tokenId, uint256 fee) external onlyOwner {
        mintFees[tokenId] = fee;
        emit MintFeeUpdated(tokenId, fee);
    }

    /**
     * @dev Public mint function for a specific token ID.
     * Requirements:
     * - The caller must send enough ETH based on the mint fee and amount.
     * @param tokenId The token type identifier.
     * @param amount Number of tokens to mint.
     */
    function mint(uint256 tokenId, uint256 amount) external payable {
        uint256 feeRequired = mintFees[tokenId] * amount;
        require(msg.value >= feeRequired, "Insufficient fee for minting");
        (bool sent, ) = feeRecipient.call{value: msg.value}("");
        require(sent, "Fee transfer failed");
        _mint(msg.sender, tokenId, amount, "");
        totalSupply[tokenId] += amount;
    }

    /**
     * @dev Allows the owner to update the fee recipient.
     * @param newFeeRecipient New fee recipient address.
     */
    function updateFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }
}
