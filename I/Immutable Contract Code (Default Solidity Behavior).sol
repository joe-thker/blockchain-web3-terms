// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ImmutableContract
/// @notice Demonstrates default immutability of deployed contract code
contract ImmutableContract {
    string public greeting = "Hello, World!";

    /// @notice Always returns a fixed response, code cannot change
    function updateGreeting(string memory) public pure returns (string memory) {
        return "Cannot update - code is immutable!";
    }
}
