// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FeeTiersERC721
 * @dev ERC721 token with fee tiers for transfers.
 * Each NFT has an associated fee (in wei) that must be paid when transferring it.
 * Standard transfer functions (transferFrom and safeTransferFrom with data) are disabled.
 * Note: The safeTransferFrom(address, address, uint256) function in the base ERC721 is non-virtual
 * and cannot be overridden. Users should be instructed to use transferWithFee.
 */
contract FeeTiersERC721 is ERC721, Ownable {
    // Mapping from token ID to its transfer fee in wei.
    mapping(uint256 => uint256) public feeForToken;
    // Address to receive the fees.
    address public feeRecipient;
    // Token ID counter.
    uint256 private _nextTokenId;

    event FeeUpdated(uint256 indexed tokenId, uint256 fee);
    event FeeRecipientUpdated(address newRecipient);
    event NFTTransferredWithFee(address indexed sender, address indexed recipient, uint256 tokenId, uint256 fee);

    /**
     * @dev Constructor sets the token name, symbol, and fee recipient.
     * @param _feeRecipient Address to receive transfer fees.
     */
    constructor(address _feeRecipient)
        ERC721("Fee Tiers ERC721", "FTE721")
        Ownable(msg.sender)
    {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
        _nextTokenId = 1;
    }

    /**
     * @dev Mints a new NFT to the owner.
     */
    function mint() external onlyOwner {
        _safeMint(msg.sender, _nextTokenId);
        _nextTokenId++;
    }

    /**
     * @dev Sets the transfer fee for a given token.
     * @param tokenId The NFT token ID.
     * @param fee The fee in wei required to transfer the token.
     */
    function setFee(uint256 tokenId, uint256 fee) external onlyOwner {
        feeForToken[tokenId] = fee;
        emit FeeUpdated(tokenId, fee);
    }

    /**
     * @dev Updates the fee recipient.
     * @param newRecipient The new fee recipient address.
     */
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    /**
     * @dev Transfers an NFT along with the required fee.
     * The caller must send at least the fee in ETH (msg.value).
     * @param recipient Address to receive the NFT.
     * @param tokenId The NFT token ID to transfer.
     */
    function transferWithFee(address recipient, uint256 tokenId) external payable {
        require(ownerOf(tokenId) == msg.sender, "Caller is not token owner");
        uint256 fee = feeForToken[tokenId];
        require(msg.value >= fee, "Insufficient fee sent");

        // Forward fee to feeRecipient.
        payable(feeRecipient).transfer(fee);
        _transfer(msg.sender, recipient, tokenId);
        emit NFTTransferredWithFee(msg.sender, recipient, tokenId, fee);
    }

    // --- Disable standard transfer functions that are virtual ---

    /**
     * @dev Overrides transferFrom to disable standard transfers.
     */
    function transferFrom(address, address, uint256) public pure override {
        revert("Use transferWithFee");
    }

    /**
     * @dev Overrides safeTransferFrom with data to disable standard transfers.
     */
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
        revert("Use transferWithFee");
    }

    // Note: The safeTransferFrom(address, address, uint256) function from ERC721 is non-virtual,
    // so it cannot be overridden. Users should be instructed not to call that function.
}
