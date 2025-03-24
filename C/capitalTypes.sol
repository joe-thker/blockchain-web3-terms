// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CryptoCapitalDictionary
/// @notice This contract acts as an on-chain dictionary for different types of capital in the crypto ecosystem.
contract CryptoCapitalDictionary {
    address public owner;

    struct CapitalInfo {
        string name;      // e.g., "Trading Capital"
        string useCases;  // Use cases description
    }

    CapitalInfo[] public capitals;

    event CapitalAdded(uint256 indexed index, string name, string useCases);
    event CapitalUpdated(uint256 indexed index, string name, string useCases);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Prepopulate the dictionary with common types of crypto capital.
        capitals.push(CapitalInfo(
            "Trading Capital",
            "Used for day trading and short-term speculation to profit from market fluctuations."
        ));
        capitals.push(CapitalInfo(
            "Investment Capital",
            "Allocated for long-term holding of assets, aiming for value appreciation over time."
        ));
        capitals.push(CapitalInfo(
            "Liquidity Capital",
            "Provided to liquidity pools on decentralized exchanges to facilitate trades and earn fees."
        ));
        capitals.push(CapitalInfo(
            "Staking Capital",
            "Locked in staking contracts to secure networks and earn rewards."
        ));
        capitals.push(CapitalInfo(
            "Venture Capital",
            "Investments from venture funds to support early-stage crypto projects and drive innovation."
        ));
    }

    /// @notice Adds a new type of capital to the dictionary.
    /// @param _name The name of the capital type.
    /// @param _useCases A description of its use cases.
    function addCapital(string calldata _name, string calldata _useCases) external onlyOwner {
        capitals.push(CapitalInfo(_name, _useCases));
        emit CapitalAdded(capitals.length - 1, _name, _useCases);
    }

    /// @notice Updates an existing capital entry.
    /// @param index The index of the capital to update.
    /// @param _name The new name.
    /// @param _useCases The new description of use cases.
    function updateCapital(uint256 index, string calldata _name, string calldata _useCases) external onlyOwner {
        require(index < capitals.length, "Invalid index");
        capitals[index] = CapitalInfo(_name, _useCases);
        emit CapitalUpdated(index, _name, _useCases);
    }

    /// @notice Retrieves the capital information at a given index.
    /// @param index The index of the capital entry.
    /// @return The CapitalInfo struct containing the name and use cases.
    function getCapital(uint256 index) external view returns (CapitalInfo memory) {
        require(index < capitals.length, "Invalid index");
        return capitals[index];
    }

    /// @notice Returns the total number of capital types stored.
    /// @return The count of capital entries.
    function getCapitalCount() external view returns (uint256) {
        return capitals.length;
    }
}
