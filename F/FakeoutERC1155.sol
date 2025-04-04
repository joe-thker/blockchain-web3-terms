// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title FakeoutERC1155
 * @dev ERC1155 multi-token contract with token-specific mint fees and pausable ("Fakeout") functionality.
 */
contract FakeoutERC1155 is ERC1155, Ownable, Pausable {
    // Mapping for token-specific mint fees
    mapping(uint256 => uint256) public mintFees;
    // Address that receives the mint fees
    address public feeRecipient;
    
    // Mapping to track total supply for each token id
    mapping(uint256 => uint256) public totalSupply;
    
    event MintFeeUpdated(uint256 tokenId, uint256 newMintFee);
    event FeeRecipientUpdated(address newFeeRecipient);
    event FakeOutTriggered(address indexed triggeredBy);
    event Resumed(address indexed resumedBy);
    
    /**
     * @dev Constructor sets the base URI and fee recipient.
     * @param uri Base URI for token metadata.
     * @param _feeRecipient Address to receive mint fees.
     */
    constructor(string memory uri, address _feeRecipient)
        ERC1155(uri)
        Ownable(msg.sender)
    {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }
    
    /**
     * @dev Owner can set the mint fee for a specific token type.
     */
    function setMintFee(uint256 tokenId, uint256 fee) external onlyOwner {
        mintFees[tokenId] = fee;
        emit MintFeeUpdated(tokenId, fee);
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
     * @dev Mint tokens of a specific type. Requires payment of the token’s mint fee.
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
    
    /**
     * @dev Custom _beforeTokenTransfer hook to enforce pausable functionality.
     * Parameter names are omitted to avoid unused variable warnings.
     * We removed the override specifier because no parent function is being overridden.
     */
    function _beforeTokenTransfer(
        address,           // operator
        address,           // from
        address,           // to
        uint256[] memory,  // ids
        uint256[] memory,  // amounts
        bytes memory       // data
    ) internal {
        require(!paused(), "ERC1155: token transfer while paused");
    }
}
