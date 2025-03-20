// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BenchmarkIndexDictionary
/// @notice A contract to store and retrieve the definition and use cases of "Benchmark Index".
contract BenchmarkIndexDictionary {
    // Public variable for the term.
    string public term = "Benchmark Index";
    
    // Public variable for the definition.
    string public definition = "A benchmark index is a statistical measure representing the performance of a group of assets or securities. It is used for performance evaluation, portfolio construction, risk management, and market analysis.";

    /// @notice Retrieves the definition of Benchmark Index.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }
}
