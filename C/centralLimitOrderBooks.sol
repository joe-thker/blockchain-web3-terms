// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CentralLimitOrderBook {
    // Structure for an order in the order book.
    struct Order {
        uint256 id;
        address trader;
        bool isBuy;     // True if it's a buy order, false if sell order.
        uint256 price;  // Price per unit (in wei, for example).
        uint256 amount; // Amount of tokens to buy or sell.
        bool filled;    // Indicates if the order is completely filled.
    }
    
    Order[] public orders;
    uint256 public nextOrderId;
    
    event OrderPlaced(uint256 indexed orderId, address indexed trader, bool isBuy, uint256 price, uint256 amount);
    event OrderMatched(uint256 indexed buyOrderId, uint256 indexed sellOrderId, uint256 matchPrice, uint256 matchAmount);

    /// @notice Places an order in the order book.
    /// @param isBuy True for a buy order, false for a sell order.
    /// @param price The limit price per token.
    /// @param amount The amount of tokens to buy or sell.
    function placeOrder(bool isBuy, uint256 price, uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(price > 0, "Price must be > 0");
        
        orders.push(Order({
            id: nextOrderId,
            trader: msg.sender,
            isBuy: isBuy,
            price: price,
            amount: amount,
            filled: false
        }));
        emit OrderPlaced(nextOrderId, msg.sender, isBuy, price, amount);
        nextOrderId++;
    }
    
    /// @notice Matches buy and sell orders if the buy order's price is equal to or exceeds the sell order's price.
    /// This is a simple matching function that iterates over all orders.
    function matchOrders() external {
        // Loop through each buy order.
        for (uint256 i = 0; i < orders.length; i++) {
            Order storage buyOrder = orders[i];
            if (buyOrder.filled || !buyOrder.isBuy) continue;
            
            // For each buy order, try to find a matching sell order.
            for (uint256 j = 0; j < orders.length; j++) {
                Order storage sellOrder = orders[j];
                if (sellOrder.filled || sellOrder.isBuy) continue;
                
                // Check if the buy order price meets or exceeds the sell order price.
                if (buyOrder.price >= sellOrder.price) {
                    // Determine the match amount (the lesser of the two orders' remaining amounts).
                    uint256 matchAmount = buyOrder.amount < sellOrder.amount ? buyOrder.amount : sellOrder.amount;
                    
                    // Reduce the order amounts accordingly.
                    buyOrder.amount -= matchAmount;
                    sellOrder.amount -= matchAmount;
                    
                    emit OrderMatched(buyOrder.id, sellOrder.id, sellOrder.price, matchAmount);
                    
                    // If the buy order is fully filled, mark it and break to the next buy order.
                    if (buyOrder.amount == 0) {
                        buyOrder.filled = true;
                        break;
                    }
                    
                    // If the sell order is fully filled, mark it.
                    if (sellOrder.amount == 0) {
                        sellOrder.filled = true;
                    }
                }
            }
        }
    }
    
    /// @notice Retrieves a specific order by its ID.
    /// @param orderId The ID of the order.
    /// @return The order struct.
    function getOrder(uint256 orderId) external view returns (Order memory) {
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].id == orderId) {
                return orders[i];
            }
        }
        revert("Order not found");
    }
    
    /// @notice Returns the total number of orders in the order book.
    /// @return The count of orders.
    function getOrderCount() external view returns (uint256) {
        return orders.length;
    }
}
