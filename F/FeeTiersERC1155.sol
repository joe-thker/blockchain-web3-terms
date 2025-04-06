// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FeeTiersERC1155
 * @dev ERC1155 token with fee tiers per token type.
 * For each transfer, the fee is computed based on pre-defined fee tiers for that token ID.
 * The fee is transferred to a fee recipient, and the net amount is delivered to the recipient.
 */
contract FeeTiersERC1155 is ERC1155, Ownable {
    // Structure for a fee tier.
    struct FeeTier {
        uint256 minAmount; // Minimum transfer amount for this tier.
        uint256 maxAmount; // Maximum transfer amount; 0 means no limit.
        uint256 feeBP;     // Fee in basis points (e.g., 50 means 0.5% fee).
    }

    // Mapping from token ID to an array of fee tiers.
    mapping(uint256 => FeeTier[]) public feeTiers;
    // Address that receives the fees.
    address public feeRecipient;

    event FeeTierAdded(uint256 indexed tokenId, uint256 indexed index, uint256 minAmount, uint256 maxAmount, uint256 feeBP);
    event FeeTierUpdated(uint256 indexed tokenId, uint256 indexed index, uint256 minAmount, uint256 maxAmount, uint256 feeBP);
    event FeeTierRemoved(uint256 indexed tokenId, uint256 indexed index);
    event FeeRecipientUpdated(address newFeeRecipient);

    /**
     * @dev Constructor sets the base URI and fee recipient.
     * @param uri_ Base URI for token metadata.
     * @param _feeRecipient Address to receive fees.
     */
    constructor(string memory uri_, address _feeRecipient)
        ERC1155(uri_)
        Ownable(msg.sender)
    {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    /// @dev Allows the owner to update the fee recipient.
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    /// @dev Adds a new fee tier for a specific token ID.
    function addFeeTier(uint256 tokenId, uint256 minAmount, uint256 maxAmount, uint256 feeBP) external onlyOwner {
        require(feeBP <= 10000, "Fee too high");
        feeTiers[tokenId].push(FeeTier(minAmount, maxAmount, feeBP));
        emit FeeTierAdded(tokenId, feeTiers[tokenId].length - 1, minAmount, maxAmount, feeBP);
    }

    /// @dev Updates a fee tier for a specific token ID.
    function updateFeeTier(uint256 tokenId, uint256 index, uint256 minAmount, uint256 maxAmount, uint256 feeBP) external onlyOwner {
        require(index < feeTiers[tokenId].length, "Invalid index");
        require(feeBP <= 10000, "Fee too high");
        feeTiers[tokenId][index] = FeeTier(minAmount, maxAmount, feeBP);
        emit FeeTierUpdated(tokenId, index, minAmount, maxAmount, feeBP);
    }

    /// @dev Removes a fee tier for a specific token ID.
    function removeFeeTier(uint256 tokenId, uint256 index) external onlyOwner {
        require(index < feeTiers[tokenId].length, "Invalid index");
        feeTiers[tokenId][index] = feeTiers[tokenId][feeTiers[tokenId].length - 1];
        feeTiers[tokenId].pop();
        emit FeeTierRemoved(tokenId, index);
    }

    /// @dev Returns the fee (in token units) for a given amount and token ID.
    function getFeeForAmount(uint256 tokenId, uint256 amount) public view returns (uint256 fee) {
        FeeTier[] memory tiers = feeTiers[tokenId];
        for (uint256 i = 0; i < tiers.length; i++) {
            FeeTier memory tier = tiers[i];
            if (amount >= tier.minAmount && (tier.maxAmount == 0 || amount <= tier.maxAmount)) {
                return (amount * tier.feeBP) / 10000;
            }
        }
        return 0;
    }

    /**
     * @dev Overrides safeTransferFrom to apply fee tiers on a single token transfer.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        uint256 fee = getFeeForAmount(id, amount);
        uint256 netAmount = amount - fee;
        // Transfer the net amount to the recipient.
        super.safeTransferFrom(from, to, id, netAmount, data);
        // Transfer fee to feeRecipient.
        super.safeTransferFrom(from, feeRecipient, id, fee, data);
    }

    /**
     * @dev Overrides safeBatchTransferFrom to apply fee tiers on batch transfers.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        uint256 length = ids.length;
        uint256[] memory netAmounts = new uint256[](length);
        uint256[] memory fees = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 feeForThis = getFeeForAmount(ids[i], amounts[i]);
            fees[i] = feeForThis;
            netAmounts[i] = amounts[i] - feeForThis;
        }
        // Transfer net amounts.
        super.safeBatchTransferFrom(from, to, ids, netAmounts, data);
        // For each token, transfer the fee to feeRecipient.
        for (uint256 i = 0; i < length; i++) {
            super.safeTransferFrom(from, feeRecipient, ids[i], fees[i], data);
        }
    }
}
