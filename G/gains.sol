// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GainTracker {
    address public owner;
    uint256 public currentPrice; // Simulated price per share in USD (multiplied by 1e18)

    struct Position {
        uint256 amountDeposited;
        uint256 buyPrice; // price at deposit (in 1e18 units)
        bool exists;
    }

    mapping(address => Position) public positions;
    mapping(address => int256) public lastReportedGain; // in USD (1e18)

    event Deposited(address indexed user, uint256 amount, uint256 priceAtBuy);
    event PriceUpdated(uint256 newPrice);
    event Withdrawn(address indexed user, uint256 amount, int256 gain);
    event GainReported(address indexed user, int256 gain);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        currentPrice = 1e18; // $1.00 initially
    }

    // Simulates depositing "shares" at current price
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit must be > 0");
        require(!positions[msg.sender].exists, "Already deposited");

        positions[msg.sender] = Position({
            amountDeposited: amount,
            buyPrice: currentPrice,
            exists: true
        });

        emit Deposited(msg.sender, amount, currentPrice);
    }

    // Update simulated price (only owner)
    function updatePrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be positive");
        currentPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    // View current gain/loss for a user (in USD * 1e18)
    function getGain(address user) public view returns (int256) {
        Position memory pos = positions[user];
        if (!pos.exists) return 0;

        uint256 initial = pos.amountDeposited * pos.buyPrice;
        uint256 current = pos.amountDeposited * currentPrice;

        return int256(current) - int256(initial);
    }

    // Simulate withdrawing and realizing gains/losses
    function withdraw() external {
        require(positions[msg.sender].exists, "No position");

        int256 gain = getGain(msg.sender);
        delete positions[msg.sender];
        lastReportedGain[msg.sender] = gain;

        emit Withdrawn(msg.sender, block.timestamp, gain);
        emit GainReported(msg.sender, gain);
    }

    // View last recorded gain/loss
    function getLastGain(address user) external view returns (int256) {
        return lastReportedGain[user];
    }
}
