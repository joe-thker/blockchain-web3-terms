// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FATFTravelRuleERC1155
 * @dev ERC1155 token that enforces FATF Travel Rule by requiring travel rule data on transfers.
 * Standard safeTransferFrom functions are disabled.
 */
contract FATFTravelRuleERC1155 is ERC1155, Ownable {
    // Emitted when a travel rule compliant transfer occurs.
    event TravelRuleTransfer(
        address indexed sender,
        address indexed recipient,
        uint256 id,
        uint256 amount,
        string originatorInfo,
        string beneficiaryInfo
    );

    /**
     * @dev Constructor sets the base URI and owner.
     * @param uri_ Base URI for token metadata.
     */
    constructor(string memory uri_) ERC1155(uri_) Ownable(msg.sender) {}

    /**
     * @dev Mints tokens of a given ID.
     * @param id Token ID to mint.
     * @param amount Number of tokens to mint.
     */
    function mint(uint256 id, uint256 amount) external onlyOwner {
        _mint(msg.sender, id, amount, "");
    }

    /**
     * @dev Transfers tokens with the required FATF Travel Rule data.
     * @param recipient Address receiving the tokens.
     * @param id Token ID.
     * @param amount Amount to transfer.
     * @param originatorInfo Required info for the sender.
     * @param beneficiaryInfo Required info for the recipient.
     */
    function transferWithTravelRule(
        address recipient,
        uint256 id,
        uint256 amount,
        string calldata originatorInfo,
        string calldata beneficiaryInfo
    ) external {
        require(bytes(originatorInfo).length > 0, "Originator info required");
        require(bytes(beneficiaryInfo).length > 0, "Beneficiary info required");
        _safeTransferFrom(msg.sender, recipient, id, amount, "");
        emit TravelRuleTransfer(msg.sender, recipient, id, amount, originatorInfo, beneficiaryInfo);
    }

    // Disable standard transfer functions.
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert("Use transferWithTravelRule");
    }
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert("Use transferWithTravelRule");
    }
}
