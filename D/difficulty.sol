// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DifficultyManager
/// @notice A dynamic and optimized contract that maintains a difficulty parameter
/// and allows users to submit solutions (like a simplified puzzle or proof-of-work).
/// The owner can update the difficulty threshold on-the-fly.
contract DifficultyManager is Ownable, ReentrancyGuard {
    /// @notice The difficulty threshold (e.g., a target below which the solution hash must fall).
    uint256 public difficulty;

    /// @notice Mapping from user address to last solution hash submitted, for demonstration.
    mapping(address => bytes32) public userSolutions;

    // --- Events ---
    event DifficultyUpdated(uint256 newDifficulty);
    event SolutionSubmitted(address indexed user, bytes32 solutionHash, bool success);

    /// @notice Constructor sets the deployer as the initial owner and a starting difficulty.
    /// @param initialDifficulty The initial difficulty threshold.
    constructor(uint256 initialDifficulty) Ownable(msg.sender) {
        require(initialDifficulty > 0, "Difficulty must be > 0");
        difficulty = initialDifficulty;
    }

    /// @notice Owner can update the difficulty threshold dynamically.
    /// @param newDifficulty The new difficulty threshold.
    function updateDifficulty(uint256 newDifficulty) external onlyOwner {
        require(newDifficulty > 0, "Difficulty must be > 0");
        difficulty = newDifficulty;
        emit DifficultyUpdated(newDifficulty);
    }

    /// @notice Submits a “solution” by providing a nonce. A simple hash check demonstrates
    /// how difficulty might be applied (e.g. if uint256(hash) < difficulty).
    /// @param nonce Arbitrary user-chosen number or data to “solve” the puzzle.
    function submitSolution(uint256 nonce) external nonReentrant {
        // Compute the solution hash from difficulty + user address + nonce, for demonstration.
        bytes32 solutionHash = keccak256(abi.encodePacked(difficulty, msg.sender, nonce));

        // For demonstration: consider the user “successful” if the solutionHash is below the numeric difficulty.
        // e.g. if we treat difficulty as a target, then require( uint256(solutionHash) < difficulty).
        // Here we just do a check to illustrate success/fail.
        bool success = (uint256(solutionHash) < difficulty);

        userSolutions[msg.sender] = solutionHash;

        emit SolutionSubmitted(msg.sender, solutionHash, success);

        if (!success) {
            revert("Solution fails the difficulty threshold");
        }
        // If success, you could further reward the user here or track successes, etc.
    }

    /// @notice Returns the last solution hash submitted by a user.
    /// @param user The address of the user.
    /// @return The solutionHash last recorded for that user.
    function getUserSolution(address user) external view returns (bytes32) {
        return userSolutions[user];
    }
}
