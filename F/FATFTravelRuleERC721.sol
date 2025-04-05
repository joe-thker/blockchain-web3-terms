// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FATFTravelRuleERC721
 * @dev ERC721 token that requires FATF Travel Rule data on transfers.
 * Standard transfer functions are disabled where possible.
 * Use transferWithTravelRule to transfer tokens with the required travel rule data.
 */
contract FATFTravelRuleERC721 is ERC721, Ownable {
    // Event emitted when a travel rule compliant NFT transfer occurs.
    event TravelRuleTransfer(
        address indexed sender,
        address indexed recipient,
        uint256 tokenId,
        string originatorInfo,
        string beneficiaryInfo
    );

    uint256 private _nextTokenId;

    /**
     * @dev Constructor sets the token name, symbol, and the deployer as owner.
     */
    constructor() ERC721("FATF Travel Rule ERC721", "FTR721") Ownable(msg.sender) {
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
     * @dev Transfers an NFT along with the required FATF Travel Rule data.
     * Reverts if the caller is not the token owner or if the travel rule data is missing.
     * @param recipient Address receiving the NFT.
     * @param tokenId The NFT to transfer.
     * @param originatorInfo Required info for the sender (e.g. KYC identifier).
     * @param beneficiaryInfo Required info for the recipient.
     */
    function transferWithTravelRule(
        address recipient,
        uint256 tokenId,
        string calldata originatorInfo,
        string calldata beneficiaryInfo
    ) external {
        require(ownerOf(tokenId) == msg.sender, "Caller is not token owner");
        require(bytes(originatorInfo).length > 0, "Originator info required");
        require(bytes(beneficiaryInfo).length > 0, "Beneficiary info required");

        _transfer(msg.sender, recipient, tokenId);
        emit TravelRuleTransfer(msg.sender, recipient, tokenId, originatorInfo, beneficiaryInfo);
    }

    // --- Disable standard transfer methods that are virtual ---

    /**
     * @dev Overrides transferFrom (which is virtual) to disable standard transfers.
     */
    function transferFrom(address, address, uint256) public pure override {
        revert("Use transferWithTravelRule");
    }

    /**
     * @dev Overrides safeTransferFrom with data (which is virtual) to disable standard transfers.
     */
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
        revert("Use transferWithTravelRule");
    }

    // Note: We do NOT override safeTransferFrom(address, address, uint256)
    // because it is non-virtual in OpenZeppelin's ERC721. Users should be warned
    // not to use that function.
}
