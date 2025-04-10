// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title LimitOrderTypes
/// @notice Demonstrates different types of limit order mechanisms in Solidity

/// 1. Basic Limit Order (One-shot Match)
contract BasicLimitOrder {
    struct Order {
        address trader;
        uint256 price;
        uint256 amount;
        bool filled;
    }

    Order[] public orders;

    function placeOrder(uint256 price, uint256 amount) external {
        orders.push(Order(msg.sender, price, amount, false));
    }

    function fillOrder(uint256 index) external payable {
        Order storage o = orders[index];
        require(!o.filled, "Order filled");
        require(msg.value >= o.price * o.amount, "Insufficient ETH");
        o.filled = true;
        payable(o.trader).transfer(msg.value);
    }
}

/// 2. Expiring Limit Order
contract ExpiringLimitOrder {
    struct Order {
        address trader;
        uint256 price;
        uint256 amount;
        uint256 expiry;
        bool filled;
    }

    Order[] public orders;

    function placeOrder(uint256 price, uint256 amount, uint256 duration) external {
        orders.push(Order(msg.sender, price, amount, block.timestamp + duration, false));
    }

    function fillOrder(uint256 index) external payable {
        Order storage o = orders[index];
        require(!o.filled, "Order filled");
        require(block.timestamp < o.expiry, "Order expired");
        require(msg.value >= o.price * o.amount, "Insufficient ETH");
        o.filled = true;
        payable(o.trader).transfer(msg.value);
    }
}

/// 3. Cancelable Limit Order
contract CancelableLimitOrder {
    struct Order {
        address trader;
        uint256 price;
        uint256 amount;
        bool filled;
        bool cancelled;
    }

    Order[] public orders;

    function placeOrder(uint256 price, uint256 amount) external {
        orders.push(Order(msg.sender, price, amount, false, false));
    }

    function cancelOrder(uint256 index) external {
        require(orders[index].trader == msg.sender, "Not your order");
        orders[index].cancelled = true;
    }

    function fillOrder(uint256 index) external payable {
        Order storage o = orders[index];
        require(!o.filled && !o.cancelled, "Not active");
        require(msg.value >= o.price * o.amount, "Insufficient ETH");
        o.filled = true;
        payable(o.trader).transfer(msg.value);
    }
}

/// 4. Partial Fill Limit Order
contract PartialFillLimitOrder {
    struct Order {
        address trader;
        uint256 price;
        uint256 amountRemaining;
    }

    Order[] public orders;

    function placeOrder(uint256 price, uint256 amount) external {
        orders.push(Order(msg.sender, price, amount));
    }

    function fillPartial(uint256 index, uint256 amountToFill) external payable {
        Order storage o = orders[index];
        require(amountToFill <= o.amountRemaining, "Too much");
        require(msg.value >= o.price * amountToFill, "Insufficient ETH");
        o.amountRemaining -= amountToFill;
        payable(o.trader).transfer(msg.value);
    }
}

/// 5. Token-Based Limit Order (ERC20 Swap)
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenLimitOrder {
    struct Order {
        address trader;
        address tokenSell;
        address tokenBuy;
        uint256 amountSell;
        uint256 price; // tokenBuy per unit of tokenSell
        bool filled;
    }

    Order[] public orders;

    function placeOrder(address tokenSell, address tokenBuy, uint256 amountSell, uint256 price) external {
        IERC20(tokenSell).transferFrom(msg.sender, address(this), amountSell);
        orders.push(Order(msg.sender, tokenSell, tokenBuy, amountSell, price, false));
    }

    function fillOrder(uint256 index, uint256 amountBuy) external {
        Order storage o = orders[index];
        require(!o.filled, "Filled");
        uint256 cost = (amountBuy * o.price) / 1e18;
        require(amountBuy <= o.amountSell, "Exceeds order");

        IERC20(o.tokenBuy).transferFrom(msg.sender, o.trader, cost);
        IERC20(o.tokenSell).transfer(msg.sender, amountBuy);

        o.amountSell -= amountBuy;
        if (o.amountSell == 0) o.filled = true;
    }
}
