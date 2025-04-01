// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DelistingRegistry
/// @notice This contract allows the owner to list assets and later delist or update them dynamically.
/// Each asset has an ID, name, symbol, listing date, and an active status.
contract DelistingRegistry is Ownable, ReentrancyGuard {
    struct Asset {
        uint256 assetId;
        string name;
        string symbol;
        uint256 listingDate;
        bool isListed;
    }
    
    uint256 public nextAssetId;
    mapping(uint256 => Asset) public assets;
    uint256[] private listedAssetIds;

    // --- Events ---
    event AssetListed(uint256 indexed assetId, string name, string symbol, uint256 listingDate);
    event AssetUpdated(uint256 indexed assetId, string name, string symbol);
    event AssetDelisted(uint256 indexed assetId, uint256 delistingDate);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Lists a new asset.
    /// @param name The name of the asset.
    /// @param symbol The symbol of the asset.
    /// @return assetId The unique ID assigned to the asset.
    function listAsset(string calldata name, string calldata symbol)
        external
        onlyOwner
        nonReentrant
        returns (uint256 assetId)
    {
        require(bytes(name).length > 0, "Name required");
        require(bytes(symbol).length > 0, "Symbol required");
        
        assetId = nextAssetId++;
        assets[assetId] = Asset({
            assetId: assetId,
            name: name,
            symbol: symbol,
            listingDate: block.timestamp,
            isListed: true
        });
        listedAssetIds.push(assetId);

        emit AssetListed(assetId, name, symbol, block.timestamp);
    }

    /// @notice Updates details of an existing listed asset.
    /// @param assetId The asset's ID.
    /// @param newName The new name.
    /// @param newSymbol The new symbol.
    function updateAsset(uint256 assetId, string calldata newName, string calldata newSymbol)
        external
        onlyOwner
        nonReentrant
    {
        Asset storage asset = assets[assetId];
        require(asset.isListed, "Asset not listed");
        require(bytes(newName).length > 0, "Name required");
        require(bytes(newSymbol).length > 0, "Symbol required");

        asset.name = newName;
        asset.symbol = newSymbol;
        // Optionally, update listingDate if you want to record update time:
        asset.listingDate = block.timestamp;

        emit AssetUpdated(assetId, newName, newSymbol);
    }

    /// @notice Delists an asset.
    /// @param assetId The asset's ID.
    function delistAsset(uint256 assetId) external onlyOwner nonReentrant {
        Asset storage asset = assets[assetId];
        require(asset.isListed, "Asset already delisted");

        asset.isListed = false;
        _removeAssetId(assetId);

        emit AssetDelisted(assetId, block.timestamp);
    }

    /// @notice Internal helper to remove an asset ID from the active list.
    /// @param assetId The asset ID to remove.
    function _removeAssetId(uint256 assetId) internal {
        uint256 len = listedAssetIds.length;
        for (uint256 i = 0; i < len; i++) {
            if (listedAssetIds[i] == assetId) {
                listedAssetIds[i] = listedAssetIds[len - 1];
                listedAssetIds.pop();
                break;
            }
        }
    }

    /// @notice Retrieves an asset's details.
    /// @param assetId The asset's ID.
    /// @return The Asset struct.
    function getAsset(uint256 assetId) external view returns (Asset memory) {
        require(assets[assetId].listingDate != 0, "Asset does not exist");
        return assets[assetId];
    }

    /// @notice Retrieves all active (listed) asset IDs.
    /// @return An array of active asset IDs.
    function getActiveAssetIds() external view returns (uint256[] memory) {
        return listedAssetIds;
    }

    /// @notice Returns the total number of assets ever created.
    /// @return The total asset count.
    function totalAssets() external view returns (uint256) {
        return nextAssetId;
    }
}
