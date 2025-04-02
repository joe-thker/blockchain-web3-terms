// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DigitalAssetEcosystem
/// @notice A dynamic, optimized contract that manages a registry of various digital assets (e.g., ERC20, ERC721, or other on-chain references).
/// Owners can register, update, or remove assets from the ecosystem. The contract stores minimal metadata and ensures
/// secure operations using ReentrancyGuard.
contract DigitalAssetEcosystem is Ownable, ReentrancyGuard {
    /// @notice Represents possible types of digital assets (ERC20, ERC721, or other).
    enum AssetType { ERC20, ERC721, Other }

    /// @notice Structure representing a digital asset in this ecosystem.
    struct Asset {
        uint256 id;              // Unique ID of this asset in the registry
        AssetType assetType;     // The enumerated type of asset
        address assetAddress;    // The on-chain address for this asset (token contract, etc.)
        string metadataURI;      // Optional URI pointing to metadata
        bool active;             // Whether the asset is active or removed
    }

    // Array of assets
    Asset[] public assetList;

    // Mapping from assetAddress => index+1 in assetList for quick existence checks
    mapping(address => uint256) public assetIndexPlusOne;

    // --- Events ---
    event AssetRegistered(uint256 indexed id, AssetType assetType, address indexed assetAddress, string metadataURI);
    event AssetUpdated(uint256 indexed id, AssetType newType, string newMetadataURI);
    event AssetRemoved(uint256 indexed id);

    /// @notice Constructor sets the deployer as the initial owner, fixing the missing constructor arguments issue.
    constructor() Ownable(msg.sender) {}

    /// @notice Registers a new digital asset. Only the owner can register.
    /// @param assetAddr The address of the digital asset contract (ERC20, ERC721, etc.).
    /// @param aType The enumerated asset type.
    /// @param metadataURI An optional metadata URI describing the asset.
    /// @return assetId The ID assigned to this asset in the list.
    function registerAsset(address assetAddr, AssetType aType, string calldata metadataURI)
        external
        onlyOwner
        nonReentrant
        returns (uint256 assetId)
    {
        require(assetAddr != address(0), "Invalid asset address");
        require(assetIndexPlusOne[assetAddr] == 0, "Asset already registered");

        assetId = assetList.length;
        assetList.push(Asset({
            id: assetId,
            assetType: aType,
            assetAddress: assetAddr,
            metadataURI: metadataURI,
            active: true
        }));
        assetIndexPlusOne[assetAddr] = assetId + 1;

        emit AssetRegistered(assetId, aType, assetAddr, metadataURI);
    }

    /// @notice Updates an existing asset’s type or metadata. Only the owner can update.
    /// @param index The index in the assetList (this is also the asset’s ID).
    /// @param newType The new asset type (e.g., from ERC20 to Other).
    /// @param newMetadataURI The new metadata URI.
    function updateAsset(uint256 index, AssetType newType, string calldata newMetadataURI)
        external
        onlyOwner
        nonReentrant
    {
        require(index < assetList.length, "Index out of range");
        Asset storage asset = assetList[index];
        require(asset.active, "Asset already removed");

        asset.assetType = newType;
        asset.metadataURI = newMetadataURI;

        emit AssetUpdated(asset.id, newType, newMetadataURI);
    }

    /// @notice Removes (marks as inactive) an asset from the ecosystem. Only the owner can remove.
    /// @param index The index of the asset in assetList.
    function removeAsset(uint256 index) external onlyOwner nonReentrant {
        require(index < assetList.length, "Index out of range");
        Asset storage asset = assetList[index];
        require(asset.active, "Asset already removed");

        asset.active = false;
        // Clear from assetIndexPlusOne
        assetIndexPlusOne[asset.assetAddress] = 0;

        emit AssetRemoved(asset.id);
    }

    /// @notice Retrieves an asset by its index in the assetList.
    /// @param index The index in the assetList (the asset ID).
    /// @return The Asset struct for that index.
    function getAsset(uint256 index) external view returns (Asset memory) {
        require(index < assetList.length, "Index out of range");
        return assetList[index];
    }

    /// @notice Returns an array of all currently active assets in the ecosystem.
    /// @return activeAssets A dynamic array of all active Asset structs.
    function listActiveAssets() external view returns (Asset[] memory activeAssets) {
        uint256 count;
        for (uint256 i = 0; i < assetList.length; i++) {
            if (assetList[i].active) {
                count++;
            }
        }
        activeAssets = new Asset[](count);

        uint256 idx;
        for (uint256 i = 0; i < assetList.length; i++) {
            if (assetList[i].active) {
                activeAssets[idx++] = assetList[i];
            }
        }
    }

    /// @notice Returns the total number of assets ever registered (including removed).
    /// @return The length of the assetList array.
    function totalAssetCount() external view returns (uint256) {
        return assetList.length;
    }
}
