// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BenchmarkDictionary
/// @notice A contract that stores and retrieves the definition and use cases of the term "Benchmark".
contract BenchmarkDictionary {
    // The term and its definition.
    string public term = "Benchmark";
    string public definition = "A benchmark is a standard or point of reference used to measure the performance of an investment portfolio, fund, or asset against the market or a specific index. Common use cases include performance evaluation, investment strategy comparison, risk management, and portfolio construction.";

    /// @notice Retrieves the definition of Benchmark.
    /// @return The definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }
}
