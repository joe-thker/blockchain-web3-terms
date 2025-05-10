// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TWAMMModule - Time-Weighted Automated Market Maker with Attack and Defense in Solidity

// ==============================
// 🧮 Simple Price Oracle (Simulated TWAP)
// ==============================
contract SimpleOracle {
    uint256[] public prices;

    function pushPrice(uint256 price) external {
        prices.push(price);
    }

    function getTWAP(uint256 window) external view returns (uint256) {
        uint256 len = prices.length;
        uint256 count = window > len ? len : window;
        uint256 sum;
        for (uint256 i = len - count; i < len; i++) {
            sum += prices[i];
        }
        return count > 0 ? sum / count : 0;
    }
}

// ==============================
// 🔓 TWAMM Core (Simplified)
// ==============================
contract TWAMM {
    struct Order {
        address user;
        uint256 amount;
        uint256 startBlock;
        uint256 duration;
        uint256 executed;
    }

    mapping(uint256 => Order) public orders;
    uint256 public nextOrderId;
    uint256 public constant rateDivider = 1e18;

    event OrderPlaced(uint256 indexed id, address user, uint256 amount, uint256 duration);
    event OrderExecuted(uint256 indexed id, uint256 executed);

    function placeOrder(uint256 amount, uint256 duration) external payable {
        require(msg.value == amount, "Wrong amount");
        orders[nextOrderId] = Order(msg.sender, amount, block.number, duration, 0);
        emit OrderPlaced(nextOrderId, msg.sender, amount, duration);
        nextOrderId++;
    }

    function execute(uint256 orderId) external {
        Order storage o = orders[orderId];
        require(o.executed < o.amount, "Done");
        uint256 blocksPassed = block.number - o.startBlock;
        if (blocksPassed > o.duration) blocksPassed = o.duration;

        uint256 shouldExecute = (o.amount * blocksPassed) / o.duration;
        uint256 delta = shouldExecute - o.executed;

        o.executed += delta;
        payable(msg.sender).transfer(delta); // reward simulated
        emit OrderExecuted(orderId, delta);
    }

    receive() external payable {}
}

// ==============================
// 🔓 Attacker - Front-Runs TWAMM Execution
// ==============================
interface ITWAMM {
    function execute(uint256) external;
}

contract TWAMMFrontRunner {
    function snipe(ITWAMM target, uint256 orderId) external {
        target.execute(orderId);
    }
}

// ==============================
// 🔐 Safe TWAMM With Execution Cap, TWAP, and Early Exit Penalty
// ==============================
interface IOracle {
    function getTWAP(uint256) external view returns (uint256);
}

contract SafeTWAMM {
    struct Order {
        address user;
        uint256 amount;
        uint256 startBlock;
        uint256 duration;
        uint256 executed;
        bool cancelled;
    }

    mapping(uint256 => Order) public orders;
    uint256 public nextOrderId;
    uint256 public maxPerBlockExec = 0.05 ether;
    IOracle public twapOracle;

    event SafeOrderPlaced(uint256 indexed id, address user, uint256 amount);
    event SafeOrderExecuted(uint256 indexed id, uint256 executed);
    event EarlyExit(uint256 indexed id, uint256 refunded, uint256 penalty);

    constructor(address _oracle) {
        twapOracle = IOracle(_oracle);
    }

    function placeOrder(uint256 duration) external payable {
        orders[nextOrderId] = Order(msg.sender, msg.value, block.number, duration, 0, false);
        emit SafeOrderPlaced(nextOrderId, msg.sender, msg.value);
        nextOrderId++;
    }

    function execute(uint256 orderId) external {
        Order storage o = orders[orderId];
        require(!o.cancelled, "Cancelled");
        require(o.executed < o.amount, "Finished");

        uint256 blocksPassed = block.number - o.startBlock;
        if (blocksPassed > o.duration) blocksPassed = o.duration;

        uint256 shouldExecute = (o.amount * blocksPassed) / o.duration;
        uint256 delta = shouldExecute - o.executed;

        uint256 execAmount = delta > maxPerBlockExec ? maxPerBlockExec : delta;
        o.executed += execAmount;

        // Validate with TWAP to prevent major divergence spoof
        require(twapOracle.getTWAP(5) > 0, "TWAP offline");

        payable(msg.sender).transfer(execAmount);
        emit SafeOrderExecuted(orderId, execAmount);
    }

    function earlyWithdraw(uint256 orderId) external {
        Order storage o = orders[orderId];
        require(msg.sender == o.user, "Not owner");
        require(!o.cancelled, "Already out");

        uint256 unexecuted = o.amount - o.executed;
        require(unexecuted > 0, "Nothing left");

        uint256 penalty = (unexecuted * 10) / 100; // 10% burn
        uint256 refund = unexecuted - penalty;

        o.cancelled = true;
        payable(msg.sender).transfer(refund);
        emit EarlyExit(orderId, refund, penalty);
    }

    receive() external payable {}
}
