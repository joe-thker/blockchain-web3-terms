// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TimeLockedFarm
/// @notice Time-weighted liquidity mining: the longer you stake, the more you earn
contract TimeLockedFarm {
    IERC20 public token;
    IERC20 public reward;

    struct StakeInfo {
        uint256 amount;
        uint256 startBlock;
    }

    mapping(address => StakeInfo) public stakers;

    constructor(address _token, address _reward) {
        token = IERC20(_token);
        reward = IERC20(_reward);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        stakers[msg.sender] = StakeInfo(amount, block.number);
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw() external {
        StakeInfo memory info = stakers[msg.sender];
        require(info.amount > 0, "No stake found");

        uint256 duration = block.number - info.startBlock;
        uint256 multiplier = duration > 100 ? 2 : 1;

        uint256 rewardAmount = info.amount * multiplier * 1e16; // Simple reward logic
        delete stakers[msg.sender];

        reward.transfer(msg.sender, rewardAmount);
        token.transfer(msg.sender, info.amount);
    }
}
