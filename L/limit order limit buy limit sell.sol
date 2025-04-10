// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract LimitOrderBook {
    enum OrderType { Buy, Sell }

    struct Order {
        address user;
        uint256 tokenAmount;
        uint256 priceInWei; // price per token in ETH
        OrderType orderType;
        bool isActive;
    }

    IERC20 public token;
    Order[] public orders;

    event OrderPlaced(uint256 indexed orderId, address indexed user, OrderType orderType, uint256 tokenAmount, uint256 price);
    event OrderMatched(uint256 indexed orderId, address indexed taker);
    event OrderCancelled(uint256 indexed orderId);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function placeBuyOrder(uint256 tokenAmount, uint256 pricePerTokenInWei) external payable {
        require(msg.value == tokenAmount * pricePerTokenInWei, "Incorrect ETH sent");
        orders.push(Order({
            user: msg.sender,
            tokenAmount: tokenAmount,
            priceInWei: pricePerTokenInWei,
            orderType: OrderType.Buy,
            isActive: true
        }));
        emit OrderPlaced(orders.length - 1, msg.sender, OrderType.Buy, tokenAmount, pricePerTokenInWei);
    }

    function placeSellOrder(uint256 tokenAmount, uint256 pricePerTokenInWei) external {
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        orders.push(Order({
            user: msg.sender,
            tokenAmount: tokenAmount,
            priceInWei: pricePerTokenInWei,
            orderType: OrderType.Sell,
            isActive: true
        }));
        emit OrderPlaced(orders.length - 1, msg.sender, OrderType.Sell, tokenAmount, pricePerTokenInWei);
    }

    function matchBuy(uint256 orderId) external {
        Order storage order = orders[orderId];
        require(order.isActive && order.orderType == OrderType.Buy, "Invalid buy order");

        require(token.transferFrom(msg.sender, order.user, order.tokenAmount), "Token transfer failed");
        payable(msg.sender).transfer(order.tokenAmount * order.priceInWei);

        order.isActive = false;
        emit OrderMatched(orderId, msg.sender);
    }

    function matchSell(uint256 orderId) external payable {
        Order storage order = orders[orderId];
        require(order.isActive && order.orderType == OrderType.Sell, "Invalid sell order");
        require(msg.value == order.tokenAmount * order.priceInWei, "Incorrect ETH sent");

        require(token.transfer(msg.sender, order.tokenAmount), "Token transfer failed");
        payable(order.user).transfer(msg.value);

        order.isActive = false;
        emit OrderMatched(orderId, msg.sender);
    }

    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        require(order.isActive, "Order not active");
        require(order.user == msg.sender, "Not your order");

        order.isActive = false;
        if (order.orderType == OrderType.Buy) {
            payable(msg.sender).transfer(order.tokenAmount * order.priceInWei);
        } else {
            require(token.transfer(msg.sender, order.tokenAmount), "Token refund failed");
        }

        emit OrderCancelled(orderId);
    }

    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }
}
