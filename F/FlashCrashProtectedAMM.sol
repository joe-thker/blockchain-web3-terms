// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FlashCrashProtectedAMM {
    uint256 public lastPrice;
    uint256 public maxSlippage = 10; // 10%

    event SwapRejected(string reason);
    event SwapExecuted(address user, uint256 amount, uint256 price);

    constructor(uint256 _initialPrice) {
        lastPrice = _initialPrice;
    }

    function swap(uint256 price, uint256 amount) external {
        uint256 priceDiff = price > lastPrice ? price - lastPrice : lastPrice - price;
        uint256 slippage = (priceDiff * 100) / lastPrice;

        if (slippage > maxSlippage) {
            emit SwapRejected("Slippage too high - possible flash crash");
            return;
        }

        lastPrice = price;
        emit SwapExecuted(msg.sender, amount, price);
    }
}
