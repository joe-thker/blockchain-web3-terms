// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Minimal interface of ERC721 needed to handle safe transfers.
interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title DigitalAssetCustodian
/// @notice A dynamic and optimized contract that lets users deposit and withdraw ERC721 (NFT) digital assets.
/// The contract holds NFTs in custody and only releases them to the rightful owners.
/// The owner can perform emergency withdrawals if needed.
contract DigitalAssetCustodian is Ownable, ReentrancyGuard {
    /// @notice Mapping: (NFT address => (tokenId => depositor)) tracks who deposited which token.
    /// If token is not in custody, the depositor is address(0).
    mapping(address => mapping(uint256 => address)) public tokenDepositors;

    // --- Events ---
    event NFTDeposited(address indexed depositor, address indexed nft, uint256 indexed tokenId);
    event NFTWithdrawn(address indexed withdrawer, address indexed nft, uint256 indexed tokenId);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Deposits an ERC721 token into the custodian. The user must own the token and have approved
    /// this contract for transferring it.
    /// @param nft The address of the ERC721 contract.
    /// @param tokenId The ID of the token to deposit.
    function depositNFT(address nft, uint256 tokenId) external nonReentrant {
        require(nft != address(0), "Invalid NFT address");
        require(tokenId > 0, "Invalid tokenId");

        // Transfer the NFT from the user to this contract (must have user’s approval).
        IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);

        // Record that this user is the depositor of this token.
        tokenDepositors[nft][tokenId] = msg.sender;

        emit NFTDeposited(msg.sender, nft, tokenId);
    }

    /// @notice Withdraws a previously deposited ERC721 token. Only the original depositor can withdraw it.
    /// @param nft The address of the ERC721 contract.
    /// @param tokenId The ID of the token to withdraw.
    function withdrawNFT(address nft, uint256 tokenId) external nonReentrant {
        require(nft != address(0), "Invalid NFT address");
        address depositor = tokenDepositors[nft][tokenId];
        require(depositor == msg.sender, "Not the token depositor");

        // Clear the depositor record
        tokenDepositors[nft][tokenId] = address(0);

        // Transfer the NFT from this contract back to the depositor
        IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        emit NFTWithdrawn(msg.sender, nft, tokenId);
    }

    /// @notice Owner can forcibly withdraw a token to a specified address in case of emergency or compliance needs.
    /// @param nft The address of the ERC721 contract.
    /// @param tokenId The ID of the token.
    /// @param recipient The address to which the token will be sent.
    function emergencyWithdraw(
        address nft,
        uint256 tokenId,
        address recipient
    ) external onlyOwner nonReentrant {
        require(nft != address(0), "Invalid NFT address");
        require(recipient != address(0), "Invalid recipient address");

        // Clear the depositor record
        tokenDepositors[nft][tokenId] = address(0);

        // Transfer the NFT to the recipient
        IERC721(nft).safeTransferFrom(address(this), recipient, tokenId);

        emit NFTWithdrawn(recipient, nft, tokenId);
    }
}
