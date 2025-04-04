// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FakeoutERC721
 * @dev ERC721 Token for unique collectibles with a mint fee and pausable ("Fakeout") functionality.
 */
contract FakeoutERC721 is ERC721Pausable, Ownable {
    uint256 private _nextTokenId;
    uint256 public mintFee;
    address public feeRecipient;
    
    event MintFeeUpdated(uint256 newMintFee);
    event FeeRecipientUpdated(address newFeeRecipient);
    event FakeOutTriggered(address indexed triggeredBy);
    event Resumed(address indexed resumedBy);
    
    /**
     * @dev Constructor sets the initial mint fee and fee recipient.
     * @param _mintFee Fee required to mint a new collectible.
     * @param _feeRecipient Address to receive mint fees.
     */
    constructor(uint256 _mintFee, address _feeRecipient)
        ERC721("Fakeout ERC721 Token", "F721")
        Ownable(msg.sender)
    {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        mintFee = _mintFee;
        feeRecipient = _feeRecipient;
        _nextTokenId = 1;
    }
    
    /**
     * @dev Mint a new collectible. Requires payment of the mint fee.
     */
    function mint() external payable {
        require(msg.value >= mintFee, "Insufficient mint fee");
        // Forward fee to feeRecipient
        (bool sent, ) = feeRecipient.call{value: msg.value}("");
        require(sent, "Fee transfer failed");
        _safeMint(msg.sender, _nextTokenId);
        _nextTokenId++;
    }
    
    /**
     * @dev Owner can update the mint fee.
     */
    function updateMintFee(uint256 newMintFee) external onlyOwner {
        mintFee = newMintFee;
        emit MintFeeUpdated(newMintFee);
    }
    
    /**
     * @dev Owner can update the fee recipient address.
     */
    function updateFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }
    
    /**
     * @dev Owner triggers a "FakeOut" to pause token transfers.
     */
    function fakeOut() external onlyOwner {
        _pause();
        emit FakeOutTriggered(msg.sender);
    }
    
    /**
     * @dev Owner resumes normal operations.
     */
    function resume() external onlyOwner {
        _unpause();
        emit Resumed(msg.sender);
    }
}
