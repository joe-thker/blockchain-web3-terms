// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CryptoAsset
/// @notice This contract represents a crypto asset with dynamic metadata.
/// It extends the ERC20 token standard and allows the owner to update metadata (asset type and description).
contract CryptoAsset is ERC20, Ownable {
    // Dynamic metadata for the asset.
    string public assetType;          // e.g., "Utility", "Security", "Stable", etc.
    string public assetDescription;   // A description of the asset.

    // Event emitted when metadata is updated.
    event MetadataUpdated(string newAssetType, string newAssetDescription);

    /// @notice Constructor initializes the crypto asset with a name, symbol, initial supply, asset type, and asset description.
    /// @param name_ The token name.
    /// @param symbol_ The token symbol.
    /// @param initialSupply The initial supply minted to the deployer (in the smallest unit, e.g., wei).
    /// @param _assetType The type/category of the asset.
    /// @param _assetDescription The asset description.
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        string memory _assetType,
        string memory _assetDescription
    )
        ERC20(name_, symbol_)
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
        assetType = _assetType;
        assetDescription = _assetDescription;
    }

    /// @notice Updates the asset metadata (asset type and description).
    /// @param newAssetType The new asset type.
    /// @param newAssetDescription The new asset description.
    function updateMetadata(string calldata newAssetType, string calldata newAssetDescription) external onlyOwner {
        assetType = newAssetType;
        assetDescription = newAssetDescription;
        emit MetadataUpdated(newAssetType, newAssetDescription);
    }
}
