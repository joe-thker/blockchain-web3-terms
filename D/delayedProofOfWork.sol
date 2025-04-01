// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DeployedProofOfWork
/// @notice A dynamic and optimized on-chain proof-of-work challenge contract.
/// Participants can submit solutions (nonces) that, when hashed with the current challenge and their address,
/// produce a hash value below the target threshold. Valid solutions are recorded, and the miner receives a reward.
/// The challenge, target, and reward are dynamic and can be updated by the owner.
contract DeployedProofOfWork is Ownable, ReentrancyGuard {
    // The current challenge value.
    bytes32 public challenge;
    // The difficulty target. A solution is valid if uint256(hash) < target.
    uint256 public target;
    // Reward per valid solution (in wei).
    uint256 public reward;

    // Total number of valid solutions submitted.
    uint256 public totalSolutions;
    // Mapping from miner address to number of valid solutions submitted.
    mapping(address => uint256) public solutions;

    // Events for transparency.
    event ChallengeUpdated(bytes32 newChallenge, uint256 newTarget);
    event SolutionSubmitted(
        address indexed miner,
        uint256 nonce,
        bytes32 solutionHash,
        uint256 timestamp,
        uint256 reward
    );
    event RewardUpdated(uint256 newReward);

    /// @notice Constructor initializes the proof-of-work system.
    /// @param initialChallenge The initial challenge value.
    /// @param initialTarget The initial difficulty target.
    /// @param initialReward The reward in wei for a valid solution.
    constructor(
        bytes32 initialChallenge,
        uint256 initialTarget,
        uint256 initialReward
    ) Ownable(msg.sender) {
        require(initialTarget > 0, "Target must be > 0");
        challenge = initialChallenge;
        target = initialTarget;
        reward = initialReward;
    }

    /// @notice Submits a solution by providing a nonce. If the hash meets the target, the solution is accepted.
    /// @param nonce The nonce used to solve the challenge.
    function submitSolution(uint256 nonce) external nonReentrant {
        // Compute the solution hash from the challenge, the sender's address, and the nonce.
        bytes32 solutionHash = keccak256(abi.encodePacked(challenge, msg.sender, nonce));
        require(uint256(solutionHash) < target, "Solution does not meet target");

        totalSolutions++;
        solutions[msg.sender]++;

        // If reward is set and the contract has enough balance, transfer reward.
        if (reward > 0 && address(this).balance >= reward) {
            (bool sent, ) = payable(msg.sender).call{value: reward}("");
            require(sent, "Reward transfer failed");
        }

        emit SolutionSubmitted(msg.sender, nonce, solutionHash, block.timestamp, reward);

        // Update the challenge to prevent reuse of the same solution.
        challenge = keccak256(abi.encodePacked(solutionHash, block.timestamp));
        emit ChallengeUpdated(challenge, target);
    }

    /// @notice Allows the owner to update the challenge and difficulty target dynamically.
    /// @param newChallenge The new challenge value.
    /// @param newTarget The new difficulty target.
    function updateChallengeAndTarget(bytes32 newChallenge, uint256 newTarget) external onlyOwner {
        require(newTarget > 0, "Target must be > 0");
        challenge = newChallenge;
        target = newTarget;
        emit ChallengeUpdated(newChallenge, newTarget);
    }

    /// @notice Allows the owner to update the reward amount.
    /// @param newReward The new reward in wei.
    function updateReward(uint256 newReward) external onlyOwner {
        reward = newReward;
        emit RewardUpdated(newReward);
    }

    /// @notice Fallback function to receive ETH for rewards.
    receive() external payable {}
}
