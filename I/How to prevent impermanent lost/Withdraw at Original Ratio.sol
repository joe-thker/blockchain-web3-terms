// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FixedRatioWithdrawal
/// @notice Prevents impermanent loss by withdrawing original token ratios
contract FixedRatioWithdrawal {
    struct DepositInfo {
        uint256 amountA;
        uint256 amountB;
    }

    mapping(address => DepositInfo) public deposits;

    /// @notice Deposit both tokens and store exact amounts
    function deposit(uint256 amountA, uint256 amountB, address tokenA, address tokenB) external {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        deposits[msg.sender] = DepositInfo(amountA, amountB);
    }

    /// @notice Withdraw exact tokens originally deposited, regardless of pool ratio
    function withdraw(address tokenA, address tokenB) external {
        DepositInfo memory info = deposits[msg.sender];
        require(info.amountA > 0 || info.amountB > 0, "Nothing to withdraw");

        delete deposits[msg.sender];

        IERC20(tokenA).transfer(msg.sender, info.amountA);
        IERC20(tokenB).transfer(msg.sender, info.amountB);
    }
}
