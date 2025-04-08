// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title IntrinsicValueToken
/// @notice Demonstrates how staking rewards create intrinsic value per token
contract IntrinsicValueToken is ERC20, Ownable {
    uint256 public totalRewards; // Total ETH rewards in contract

    constructor() ERC20("Intrinsic Value Token", "IVT") Ownable(msg.sender) {}

    receive() external payable {
        totalRewards += msg.value; // Value added (e.g., protocol income)
    }

    /// @notice Mint tokens (e.g., as LP or stake rewards)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Get per-token intrinsic value (in wei)
    function intrinsicValuePerToken() external view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        return totalRewards / supply;
    }

    /// @notice Redeem your share of intrinsic value
    function redeem() external {
        uint256 balance = balanceOf(msg.sender);
        require(balance > 0, "Nothing to redeem");

        uint256 share = (totalRewards * balance) / totalSupply();
        totalRewards -= share;
        _burn(msg.sender, balance);
        payable(msg.sender).transfer(share);
    }
}
