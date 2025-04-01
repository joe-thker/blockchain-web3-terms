// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DecentralizedOrderBook
/// @notice A decentralized order book that allows users to place, update, and cancel buy/sell orders.
/// The contract is dynamic (orders can be managed on the fly), optimized (using efficient mappings and arrays),
/// and secure (using Ownable for access control and ReentrancyGuard to prevent reentrancy attacks).
contract DecentralizedOrderBook is Ownable, ReentrancyGuard {
    // Order types: Buy or Sell.
    enum OrderType { Buy, Sell }

    // Structure representing an order.
    struct Order {
        uint256 id;
        address trader;
        OrderType orderType;
        uint256 price;    // Price per unit (in wei or any chosen unit)
        uint256 amount;   // Amount of asset to buy/sell
        uint256 timestamp;
        bool active;
    }

    // Incremental counter for order IDs.
    uint256 public nextOrderId;
    // Mapping from order ID to order details.
    mapping(uint256 => Order) public orders;
    // Array of active order IDs for enumeration.
    uint256[] private activeOrderIds;

    // --- Events ---
    event OrderPlaced(
        uint256 indexed id,
        address indexed trader,
        OrderType orderType,
        uint256 price,
        uint256 amount,
        uint256 timestamp
    );
    event OrderUpdated(uint256 indexed id, uint256 newPrice, uint256 newAmount);
    event OrderCancelled(uint256 indexed id);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // No additional initialization required.
    }

    /// @notice Places a new order.
    /// @param orderType The type of the order (Buy or Sell).
    /// @param price The order price per unit.
    /// @param amount The amount to buy/sell.
    /// @return orderId The unique ID of the newly placed order.
    function placeOrder(OrderType orderType, uint256 price, uint256 amount)
        external
        nonReentrant
        returns (uint256 orderId)
    {
        require(price > 0, "Price must be > 0");
        require(amount > 0, "Amount must be > 0");

        orderId = nextOrderId++;
        orders[orderId] = Order({
            id: orderId,
            trader: msg.sender,
            orderType: orderType,
            price: price,
            amount: amount,
            timestamp: block.timestamp,
            active: true
        });
        activeOrderIds.push(orderId);

        emit OrderPlaced(orderId, msg.sender, orderType, price, amount, block.timestamp);
    }

    /// @notice Updates an existing order.
    /// @param orderId The ID of the order to update.
    /// @param newPrice The new price per unit.
    /// @param newAmount The new amount to buy/sell.
    function updateOrder(uint256 orderId, uint256 newPrice, uint256 newAmount)
        external
        nonReentrant
    {
        Order storage order = orders[orderId];
        require(order.active, "Order not active");
        require(order.trader == msg.sender, "Not order owner");
        require(newPrice > 0, "Price must be > 0");
        require(newAmount > 0, "Amount must be > 0");

        order.price = newPrice;
        order.amount = newAmount;
        order.timestamp = block.timestamp; // update timestamp on change

        emit OrderUpdated(orderId, newPrice, newAmount);
    }

    /// @notice Cancels an order.
    /// @param orderId The ID of the order to cancel.
    function cancelOrder(uint256 orderId) external nonReentrant {
        Order storage order = orders[orderId];
        require(order.active, "Order not active");
        require(order.trader == msg.sender, "Not order owner");

        order.active = false;
        _removeOrderId(orderId);

        emit OrderCancelled(orderId);
    }

    /// @notice Internal function to remove an order ID from the active orders array.
    /// @param orderId The order ID to remove.
    function _removeOrderId(uint256 orderId) internal {
        uint256 len = activeOrderIds.length;
        for (uint256 i = 0; i < len; i++) {
            if (activeOrderIds[i] == orderId) {
                activeOrderIds[i] = activeOrderIds[len - 1];
                activeOrderIds.pop();
                break;
            }
        }
    }

    /// @notice Retrieves the details of an order by its ID.
    /// @param orderId The order ID.
    /// @return The Order struct.
    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    /// @notice Retrieves all active orders.
    /// @return An array of active Order structs.
    function getAllActiveOrders() external view returns (Order[] memory) {
        uint256 len = activeOrderIds.length;
        Order[] memory activeOrders = new Order[](len);
        for (uint256 i = 0; i < len; i++) {
            activeOrders[i] = orders[activeOrderIds[i]];
        }
        return activeOrders;
    }

    /// @notice Returns the total number of active orders.
    /// @return The count of active orders.
    function totalActiveOrders() external view returns (uint256) {
        return activeOrderIds.length;
    }
}
