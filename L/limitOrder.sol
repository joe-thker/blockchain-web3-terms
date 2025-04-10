// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Basic Limit Order Book (ETH → Token)
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract LimitOrderBook {
    address public tokenAddress;

    struct Order {
        address user;
        uint256 ethAmount;
        uint256 tokenAmount;
        bool isActive;
    }

    Order[] public orders;

    event OrderPlaced(uint256 indexed orderId, address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event OrderMatched(uint256 indexed orderId, address indexed taker);
    event OrderCancelled(uint256 indexed orderId);

    constructor(address _token) {
        tokenAddress = _token;
    }

    function placeLimitOrder(uint256 tokenAmount) external payable {
        require(msg.value > 0, "Must send ETH");
        orders.push(Order({
            user: msg.sender,
            ethAmount: msg.value,
            tokenAmount: tokenAmount,
            isActive: true
        }));
        emit OrderPlaced(orders.length - 1, msg.sender, msg.value, tokenAmount);
    }

    function matchOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        require(order.isActive, "Order not active");

        // Simulate 1:1 match (for demo, actual matching logic should use price comparison)
        require(IERC20(tokenAddress).transfer(order.user, order.tokenAmount), "Token transfer failed");

        payable(msg.sender).transfer(order.ethAmount);
        order.isActive = false;

        emit OrderMatched(orderId, msg.sender);
    }

    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        require(order.user == msg.sender, "Not your order");
        require(order.isActive, "Already cancelled/matched");

        payable(msg.sender).transfer(order.ethAmount);
        order.isActive = false;

        emit OrderCancelled(orderId);
    }

    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }
}
