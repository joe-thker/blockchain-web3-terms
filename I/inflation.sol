// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Time-Based Inflation Token
/// @notice Mints tokens over time at a fixed rate
contract TimeBasedInflationToken is ERC20, Ownable {
    uint256 public lastMintTime;
    uint256 public ratePerSecond = 11574074074074074; // ≈ 1e18 / 86400

    constructor() ERC20("TimeInflation", "TIME") Ownable(msg.sender) {
        lastMintTime = block.timestamp;
    }

    function mint() external onlyOwner {
        uint256 elapsed = block.timestamp - lastMintTime;
        uint256 amount = elapsed * ratePerSecond;
        _mint(msg.sender, amount);
        lastMintTime = block.timestamp;
    }
}
