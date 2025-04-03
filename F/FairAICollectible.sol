// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FairAICollectible
 * @dev ERC721 Token for unique collectibles with a mint fee.
 */
contract FairAICollectible is ERC721, Ownable {
    uint256 public nextTokenId;
    uint256 public mintFee;
    address public feeRecipient;

    event MintFeeUpdated(uint256 newMintFee);
    event FeeRecipientUpdated(address newFeeRecipient);

    /**
     * @dev Constructor sets the initial mint fee and fee recipient.
     * @param _mintFee Fee required to mint a new collectible.
     * @param _feeRecipient Address that will receive the mint fees.
     */
    constructor(
        uint256 _mintFee,
        address _feeRecipient
    ) ERC721("Fair AI Collectible", "FAIC") Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        mintFee = _mintFee;
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Mint a new collectible.
     * Requirements:
     * - The caller must send at least the mint fee.
     */
    function mint() external payable {
        require(msg.value >= mintFee, "Insufficient fee");
        // Forward fee to feeRecipient
        (bool sent, ) = feeRecipient.call{value: msg.value}("");
        require(sent, "Fee transfer failed");
        _safeMint(msg.sender, nextTokenId);
        nextTokenId++;
    }

    /**
     * @dev Allows the owner to update the mint fee.
     * @param newMintFee New fee for minting a collectible.
     */
    function updateMintFee(uint256 newMintFee) external onlyOwner {
        mintFee = newMintFee;
        emit MintFeeUpdated(newMintFee);
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
