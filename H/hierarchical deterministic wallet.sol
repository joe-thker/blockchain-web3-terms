// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title HD Wallet Index Registry
contract HDWalletIndexRegistry {
    mapping(address => mapping(uint256 => address)) public derivedAddresses;

    event AddressRegistered(address indexed master, uint256 index, address derived);

    /// @notice Register a derived address from an HD wallet path
    function registerDerived(uint256 index, address derived) external {
        require(derived != address(0), "Invalid address");
        derivedAddresses[msg.sender][index] = derived;
        emit AddressRegistered(msg.sender, index, derived);
    }

    function getDerived(address master, uint256 index) external view returns (address) {
        return derivedAddresses[master][index];
    }
}
