// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DepthChart
/// @notice A decentralized depth chart aggregator tracking bid/ask orders at various price levels.
/// Orders are aggregated by price level to minimize storage. This contract is dynamic (orders can be added,
/// updated, and canceled) and optimized (aggregates total size per price level).
contract DepthChart is ReentrancyGuard {

    // Define the two sides of the order book: Bid or Ask.
    enum OrderSide { Bid, Ask }

    // Each user order references a price and size. 
    // The total size at each price is aggregated in the depth chart.
    struct UserOrder {
        uint256 id;
        address owner;
        OrderSide side;
        uint256 price;  // price in e.g. wei or a certain base currency
        uint256 size;   // quantity for the order
        bool active;
    }

    // Next user order ID counter
    uint256 public nextOrderId;

    // Mapping from user order ID to the order details
    mapping(uint256 => UserOrder) public orders;

    // Aggregated order depth: 
    // For each (side, price) we store the total aggregated size.
    // Key: keccak256(abi.encodePacked(side, price)) -> aggregated size.
    mapping(bytes32 => uint256) public aggregatedSize;

    // Array to track active order IDs for enumeration
    uint256[] private activeOrderIds;

    // Events for logging
    event OrderPlaced(
        uint256 indexed id, 
        address indexed owner, 
        OrderSide side, 
        uint256 price, 
        uint256 size
    );

    event OrderUpdated(
        uint256 indexed id, 
        uint256 oldPrice, 
        uint256 oldSize, 
        uint256 newPrice, 
        uint256 newSize
    );

    event OrderCanceled(uint256 indexed id);

    /// @notice Internal helper to compute the aggregated size mapping key for a given side and price.
    function _sidePriceKey(OrderSide side, uint256 price) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(side, price));
    }

    /// @notice Places a new order, aggregating its size at the given price for either bid or ask side.
    /// @param side The side of the order (Bid or Ask).
    /// @param price The price for the order.
    /// @param size The size (quantity) of the order.
    /// @return orderId The unique ID assigned to the placed order.
    function placeOrder(OrderSide side, uint256 price, uint256 size)
        external
        nonReentrant
        returns (uint256 orderId)
    {
        require(price > 0, "Price must be > 0");
        require(size > 0, "Size must be > 0");

        orderId = nextOrderId++;
        orders[orderId] = UserOrder({
            id: orderId,
            owner: msg.sender,
            side: side,
            price: price,
            size: size,
            active: true
        });
        activeOrderIds.push(orderId);

        // Aggregate the size at the price level.
        bytes32 key = _sidePriceKey(side, price);
        aggregatedSize[key] += size;

        emit OrderPlaced(orderId, msg.sender, side, price, size);
    }

    /// @notice Updates an existing order with a new price and/or size.
    /// @param orderId The ID of the order to update.
    /// @param newPrice The new price of the order.
    /// @param newSize The new size of the order.
    function updateOrder(uint256 orderId, uint256 newPrice, uint256 newSize)
        external
        nonReentrant
    {
        UserOrder storage ord = orders[orderId];
        require(ord.active, "Order not active");
        require(ord.owner == msg.sender, "Not order owner");
        require(newPrice > 0, "Price must be > 0");
        require(newSize > 0, "Size must be > 0");

        // Remove old size from the old aggregated level
        bytes32 oldKey = _sidePriceKey(ord.side, ord.price);
        aggregatedSize[oldKey] -= ord.size;

        // Track old values for event
        uint256 oldPrice = ord.price;
        uint256 oldSize = ord.size;

        // Update the order with new price and size
        ord.price = newPrice;
        ord.size = newSize;

        // Add the size to the new aggregated level
        bytes32 newKey = _sidePriceKey(ord.side, newPrice);
        aggregatedSize[newKey] += newSize;

        emit OrderUpdated(orderId, oldPrice, oldSize, newPrice, newSize);
    }

    /// @notice Cancels an existing order, removing it from the depth chart aggregation.
    /// @param orderId The ID of the order to cancel.
    function cancelOrder(uint256 orderId) external nonReentrant {
        UserOrder storage ord = orders[orderId];
        require(ord.active, "Order not active");
        require(ord.owner == msg.sender, "Not order owner");

        // Mark the order inactive
        ord.active = false;

        // Remove from aggregated size
        bytes32 key = _sidePriceKey(ord.side, ord.price);
        aggregatedSize[key] -= ord.size;

        // Remove order from active list
        _removeActiveOrderId(orderId);

        emit OrderCanceled(orderId);
    }

    /// @notice Returns the aggregated size at a given side and price.
    /// @param side The order side (Bid or Ask).
    /// @param price The price level.
    /// @return The total aggregated size at that price level for the specified side.
    function getAggregatedSize(OrderSide side, uint256 price) external view returns (uint256) {
        return aggregatedSize[_sidePriceKey(side, price)];
    }

    /// @notice Retrieves the user order struct by ID.
    function getOrder(uint256 orderId) external view returns (UserOrder memory) {
        return orders[orderId];
    }

    /// @notice Returns an array of currently active order IDs.
    function getActiveOrders() external view returns (uint256[] memory) {
        return activeOrderIds;
    }

    /// @notice Returns the total number of orders ever created (including canceled).
    function totalOrders() external view returns (uint256) {
        return nextOrderId;
    }

    /// @notice Internal helper to remove an order ID from the activeOrderIds array.
    function _removeActiveOrderId(uint256 orderId) internal {
        uint256 len = activeOrderIds.length;
        for (uint256 i = 0; i < len; i++) {
            if (activeOrderIds[i] == orderId) {
                activeOrderIds[i] = activeOrderIds[len - 1];
                activeOrderIds.pop();
                break;
            }
        }
    }
}
