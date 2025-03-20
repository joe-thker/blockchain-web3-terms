// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BearTrapDictionary
/// @notice A contract that stores and retrieves the definition and use cases of "Bear Trap" in financial markets.
contract BearTrapDictionary {
    // The term and its definition
    string public term = "Bear Trap";
    string public definition = "A market situation where the price falls, luring bearish traders into short positions, only for the price to reverse upward unexpectedly, trapping them in losing positions. Use cases include trader education, risk management analysis, market analysis, and algorithmic trading strategy design.";

    /// @notice Retrieves the definition of Bear Trap.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }
}
