// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BitcoinHalvingSimulator
/// @notice This contract simulates Bitcoin's halving mechanism by calculating the current block reward.
/// @dev Bitcoin originally had a block reward of 50 BTC (expressed in satoshis, 50 * 1e8). 
///      The reward halves every 210,000 blocks. This contract uses block.number to compute the number of halvings.
contract BitcoinHalvingSimulator {
    // Initial reward: 50 BTC in satoshis (1 BTC = 100,000,000 satoshis)
    uint256 public constant INITIAL_REWARD = 50 * 1e8;
    
    // Halving interval: 210,000 blocks
    uint256 public constant HALVING_INTERVAL = 210000;

    /// @notice Calculates the current block reward based on the number of halvings.
    /// @return reward The current block reward in satoshis.
    function getCurrentReward() public view returns (uint256 reward) {
        // Calculate how many full halving periods have passed.
        uint256 halvings = block.number / HALVING_INTERVAL;
        // In Bitcoin, after 64 halvings, the reward becomes 0. Here we simply check if halvings exceed a reasonable limit.
        if (halvings >= 64) {
            return 0;
        }
        // Calculate current reward: INITIAL_REWARD / (2^halvings)
        reward = INITIAL_REWARD / (2 ** halvings);
    }
}
