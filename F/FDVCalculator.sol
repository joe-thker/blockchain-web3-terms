// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPriceFeed {
    function getTokenPrice() external view returns (uint256); // 1e18 = $1.00
}

contract FDVCalculator is Ownable {
    IERC20 public token;
    IPriceFeed public priceFeed;

    uint256 public maxSupply;         // Total planned supply
    uint256 public lockedSupply;      // Tokens not yet released

    constructor(
        address tokenAddress,
        address priceFeedAddress,
        uint256 _maxSupply,
        uint256 _initialLocked
    ) Ownable(msg.sender) {
        token = IERC20(tokenAddress);
        priceFeed = IPriceFeed(priceFeedAddress);
        maxSupply = _maxSupply;
        lockedSupply = _initialLocked;
    }

    /// 🔍 View circulating supply = total - locked
    function circulatingSupply() public view returns (uint256) {
        return maxSupply - lockedSupply;
    }

    /// 💡 Simulate unlocking tokens
    function unlockTokens(uint256 amount) external onlyOwner {
        require(amount <= lockedSupply, "Too much");
        lockedSupply -= amount;
    }

    /// 💰 Get FDV = price × total supply
    function getFDV() public view returns (uint256) {
        uint256 price = priceFeed.getTokenPrice(); // 1e18 scaled
        return (price * maxSupply) / 1e18;
    }

    /// 🪙 Get Market Cap = price × circulating supply
    function getMarketCap() public view returns (uint256) {
        uint256 price = priceFeed.getTokenPrice();
        return (price * circulatingSupply()) / 1e18;
    }
}
