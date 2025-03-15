// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BearSpreadDictionary
/// @notice A contract that provides the definition and use cases for a Bear Spread options strategy.
contract BearSpreadDictionary {
    string public term = "Bear Spread";
    string public definition = "An options trading strategy that profits from a moderate decline in the underlying asset's price by buying and selling put options at different strike prices. Use cases include hedging and speculation with limited risk.";

    /// @notice Retrieves the definition of Bear Spread.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }
}
