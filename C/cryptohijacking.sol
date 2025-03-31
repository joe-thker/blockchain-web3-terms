// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title AuthorizedMiner
/// @notice This contract simulates a protected mining function to prevent unauthorized use (crypto jacking).
/// Only addresses authorized by the owner can call the mine function to receive a pseudo-random reward.
contract AuthorizedMiner is Ownable, ReentrancyGuard {
    // Mapping to track authorized miner addresses.
    mapping(address => bool) public isAuthorizedMiner;
    // Mapping to track cumulative rewards for each miner.
    mapping(address => uint256) public rewards;

    // --- Events ---
    event MinerAuthorized(address indexed miner);
    event MinerRevoked(address indexed miner);
    event Mined(address indexed miner, uint256 reward);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // No additional initialization required.
    }

    /// @notice Allows the owner to add an authorized miner.
    /// @param miner The address to authorize.
    function authorizeMiner(address miner) external onlyOwner {
        require(miner != address(0), "Invalid miner address");
        require(!isAuthorizedMiner[miner], "Miner already authorized");
        isAuthorizedMiner[miner] = true;
        emit MinerAuthorized(miner);
    }

    /// @notice Allows the owner to revoke an authorized miner.
    /// @param miner The address to revoke.
    function revokeMiner(address miner) external onlyOwner {
        require(isAuthorizedMiner[miner], "Miner not authorized");
        isAuthorizedMiner[miner] = false;
        emit MinerRevoked(miner);
    }

    /// @notice Simulated mining function that only authorized miners can call.
    /// Computes a pseudo-random reward based on block timestamp and caller address.
    /// @return reward The reward amount generated.
    function mine() external nonReentrant returns (uint256 reward) {
        require(isAuthorizedMiner[msg.sender], "Not authorized to mine");
        // Calculate a pseudo-random reward (for demonstration only; not secure randomness).
        reward = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 1e18;
        rewards[msg.sender] += reward;
        emit Mined(msg.sender, reward);
    }
}
