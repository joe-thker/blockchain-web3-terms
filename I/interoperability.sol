// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title InteroperableVault
/// @notice Accepts any ERC20 token & reads Chainlink price oracle
contract InteroperableVault {
    AggregatorV3Interface public priceFeed;

    event TokenDeposited(address indexed user, address indexed token, uint256 amount);
    event TokenWithdrawn(address indexed user, address indexed token, uint256 amount);

    constructor(address _chainlinkFeed) {
        priceFeed = AggregatorV3Interface(_chainlinkFeed);
    }

    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Invalid amount");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit TokenDeposited(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        IERC20(token).transfer(msg.sender, amount);
        emit TokenWithdrawn(msg.sender, token, amount);
    }

    /// @notice Check latest price from Chainlink oracle
    /// @return price Latest oracle price
    function checkPrice() external view returns (int256 price) {
        (, price, , ,) = priceFeed.latestRoundData();
    }
}
