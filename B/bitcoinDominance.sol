// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BitcoinDominance {
    address public owner;
    // Bitcoin dominance stored as a percentage with 2 decimals of precision.
    // For example, a value of 5023 represents 50.23%.
    uint256 public dominance;

    event DominanceUpdated(uint256 newDominance);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can update");
        _;
    }

    /// @notice Constructor sets the contract owner and initial Bitcoin dominance.
    /// @param initialDominance The initial Bitcoin dominance (e.g., 5023 for 50.23%).
    constructor(uint256 initialDominance) {
        owner = msg.sender;
        dominance = initialDominance;
    }

    /// @notice Updates the Bitcoin dominance value. Only callable by the owner.
    /// @param newDominance The new Bitcoin dominance value (with 2 decimal precision).
    function updateDominance(uint256 newDominance) external onlyOwner {
        dominance = newDominance;
        emit DominanceUpdated(newDominance);
    }

    /// @notice Returns the current Bitcoin dominance value.
    /// @return The Bitcoin dominance (with 2 decimals of precision).
    function getDominance() external view returns (uint256) {
        return dominance;
    }
}
