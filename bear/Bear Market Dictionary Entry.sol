// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BearMarketDictionary
/// @notice A contract that provides the definition and use cases for a Bear Market.
contract BearMarketDictionary {
    string public term = "Bear Market";
    string public definition = "A prolonged period during which asset prices decline, and pessimistic sentiment prevails. Use cases include risk management, market analysis, and strategic asset allocation during downturns.";

    /// @notice Retrieves the definition of Bear Market.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }
}
