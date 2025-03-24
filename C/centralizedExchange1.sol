// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CentralizedExchange {
    address public owner;
    
    // User balances in Ether for trading
    mapping(address => uint256) public balances;

    // Order types
    enum OrderType { BUY, SELL }

    // Order structure
    struct Order {
        uint256 id;
        address trader;
        OrderType orderType;
        uint256 price;  // Price per unit (in wei)
        uint256 amount; // Amount of asset to trade
        bool filled;
    }
    
    Order[] public buyOrders;
    Order[] public sellOrders;
    uint256 public nextOrderId;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event OrderPlaced(uint256 indexed orderId, address indexed trader, OrderType orderType, uint256 price, uint256 amount);
    event OrderMatched(uint256 indexed buyOrderId, uint256 indexed sellOrderId, uint256 matchPrice, uint256 matchAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        nextOrderId = 0;
    }
    
    // Deposit Ether for trading
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be > 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // Withdraw Ether from trading account
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
    
    // Place a buy order
    function placeBuyOrder(uint256 price, uint256 amount) external {
        // Total cost required for the order
        uint256 totalCost = price * amount;
        require(balances[msg.sender] >= totalCost, "Insufficient balance for buy order");
        
        Order memory order = Order({
            id: nextOrderId,
            trader: msg.sender,
            orderType: OrderType.BUY,
            price: price,
            amount: amount,
            filled: false
        });
        buyOrders.push(order);
        emit OrderPlaced(nextOrderId, msg.sender, OrderType.BUY, price, amount);
        nextOrderId++;
    }
    
    // Place a sell order
    function placeSellOrder(uint256 price, uint256 amount) external {
        // In a real exchange, seller's assets would be locked. For simplicity, we assume they hold the asset.
        Order memory order = Order({
            id: nextOrderId,
            trader: msg.sender,
            orderType: OrderType.SELL,
            price: price,
            amount: amount,
            filled: false
        });
        sellOrders.push(order);
        emit OrderPlaced(nextOrderId, msg.sender, OrderType.SELL, price, amount);
        nextOrderId++;
    }
    
    // Match orders: simplistic matching algorithm
    // For each buy order, try to find a sell order where buy price >= sell price.
    function matchOrders() external onlyOwner {
        for (uint256 i = 0; i < buyOrders.length; i++) {
            Order storage buyOrder = buyOrders[i];
            if (buyOrder.filled) continue;
            
            for (uint256 j = 0; j < sellOrders.length; j++) {
                Order storage sellOrder = sellOrders[j];
                if (sellOrder.filled) continue;
                
                // If buy order price is equal to or higher than sell order price, match orders.
                if (buyOrder.price >= sellOrder.price) {
                    // Determine the match amount: the minimum of the two order amounts.
                    uint256 matchAmount = buyOrder.amount < sellOrder.amount ? buyOrder.amount : sellOrder.amount;
                    
                    // Update order amounts
                    buyOrder.amount -= matchAmount;
                    sellOrder.amount -= matchAmount;
                    
                    // Mark orders as filled if fully executed
                    if (buyOrder.amount == 0) {
                        buyOrder.filled = true;
                    }
                    if (sellOrder.amount == 0) {
                        sellOrder.filled = true;
                    }
                    
                    // Deduct funds from buyer and credit seller (using the sell order price)
                    uint256 cost = sellOrder.price * matchAmount;
                    require(balances[buyOrder.trader] >= cost, "Insufficient funds during match");
                    balances[buyOrder.trader] -= cost;
                    balances[sellOrder.trader] += cost;
                    
                    emit OrderMatched(buyOrder.id, sellOrder.id, sellOrder.price, matchAmount);
                }
            }
        }
    }
    
    // Get total number of buy orders
    function getBuyOrderCount() external view returns (uint256) {
        return buyOrders.length;
    }
    
    // Get total number of sell orders
    function getSellOrderCount() external view returns (uint256) {
        return sellOrders.length;
    }
}
