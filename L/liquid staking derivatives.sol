// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Liquid Staking Derivative – sETH
contract sETH {
    string public name = "Staked ETH";
    string public symbol = "sETH";
    uint8 public decimals = 18;

    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    uint256 public exchangeRate = 1e18; // starts 1:1

    receive() external payable {
        mint(msg.sender, msg.value);
    }

    function mint(address user, uint256 ethAmount) internal {
        uint256 amountToMint = (ethAmount * 1e18) / exchangeRate;
        balances[user] += amountToMint;
        totalSupply += amountToMint;
    }

    function simulateRewardDistribution(uint256 reward) external {
        require(totalSupply > 0, "No stakers");
        // increase exchange rate to reflect rewards
        exchangeRate += (reward * 1e18) / totalSupply;
    }

    function balanceOf(address user) public view returns (uint256) {
        return balances[user];
    }

    function redeem() external {
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "Nothing to redeem");
        uint256 ethAmount = (userBalance * exchangeRate) / 1e18;
        balances[msg.sender] = 0;
        totalSupply -= userBalance;
        payable(msg.sender).transfer(ethAmount);
    }
}
