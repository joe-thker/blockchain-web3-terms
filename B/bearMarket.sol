// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BearMarketDictionary
/// @notice A contract that stores the definition of "Bear Market" and its use cases.
contract BearMarketDictionary {
    // Term and its definition
    string public term = "Bear Market";
    string public definition = "A market condition characterized by falling asset prices and widespread pessimism. Common use cases include risk management, market analysis, hedging strategies, and investment timing.";

    /// @notice Retrieves the definition of Bear Market.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }
}
