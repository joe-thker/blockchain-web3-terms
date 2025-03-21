// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IBEP20
/// @notice Minimal interface for BEP-20 (or ERC-20) tokens.
interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/// @title BlockTrade
/// @notice A contract that simulates a block trade mechanism for large, privately negotiated token trades.
contract BlockTrade {
    address public owner;

    // Structure representing a block trade order.
    struct TradeOrder {
        uint256 id;          // Unique identifier for the order.
        address seller;      // Seller address.
        IBEP20 token;        // Token being sold.
        uint256 amount;      // Amount of tokens offered.
        uint256 pricePerToken; // Fixed price per token in wei.
        bool active;         // Whether the order is still active.
    }

    // Mapping from trade order ID to TradeOrder.
    mapping(uint256 => TradeOrder) public tradeOrders;
    uint256 public nextOrderId;

    event TradeOrderCreated(uint256 indexed orderId, address indexed seller, address token, uint256 amount, uint256 pricePerToken);
    event TradeOrderExecuted(uint256 indexed orderId, address indexed buyer, uint256 totalCost);
    event TradeOrderCanceled(uint256 indexed orderId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Seller creates a new block trade order.
    /// @param token The address of the token being sold.
    /// @param amount The amount of tokens to sell.
    /// @param pricePerToken The fixed price per token in wei.
    function createTradeOrder(IBEP20 token, uint256 amount, uint256 pricePerToken) external {
        require(amount > 0, "Amount must be > 0");
        require(pricePerToken > 0, "Price must be > 0");
        
        tradeOrders[nextOrderId] = TradeOrder({
            id: nextOrderId,
            seller: msg.sender,
            token: token,
            amount: amount,
            pricePerToken: pricePerToken,
            active: true
        });
        
        emit TradeOrderCreated(nextOrderId, msg.sender, address(token), amount, pricePerToken);
        nextOrderId++;
    }

    /// @notice Buyer executes a trade order by sending sufficient Ether.
    /// @param orderId The ID of the trade order to execute.
    function executeTradeOrder(uint256 orderId) external payable {
        TradeOrder storage order = tradeOrders[orderId];
        require(order.active, "Order is not active");
        uint256 totalCost = order.amount * order.pricePerToken;
        require(msg.value >= totalCost, "Insufficient Ether sent");

        // Mark order as executed.
        order.active = false;

        // Transfer tokens from seller to buyer.
        // Seller must have approved this contract to spend tokens on their behalf.
        bool success = order.token.transferFrom(order.seller, msg.sender, order.amount);
        require(success, "Token transfer failed");

        // Transfer Ether to seller.
        (bool sent, ) = order.seller.call{value: totalCost}("");
        require(sent, "Ether transfer failed");

        // Refund excess Ether, if any.
        if (msg.value > totalCost) {
            (bool refunded, ) = msg.sender.call{value: msg.value - totalCost}("");
            require(refunded, "Refund failed");
        }

        emit TradeOrderExecuted(orderId, msg.sender, totalCost);
    }

    /// @notice Seller can cancel an active trade order.
    /// @param orderId The ID of the trade order to cancel.
    function cancelTradeOrder(uint256 orderId) external {
        TradeOrder storage order = tradeOrders[orderId];
        require(order.active, "Order is not active");
        require(msg.sender == order.seller, "Not the seller");
        order.active = false;
        emit TradeOrderCanceled(orderId);
    }
}
