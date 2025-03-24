// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract IsolatedMarginTrading {
    enum PositionType { Long, Short }
    uint256 public nextPositionId;
    address public owner;
    // Dummy current market price (can be updated by the owner)
    uint256 public currentPrice;

    struct Position {
        uint256 id;
        address trader;
        PositionType positionType;
        uint256 amount;      // Position size (e.g., in coins)
        uint256 entryPrice;  // Price when position is opened
        uint256 collateral;  // Collateral deposited for this position
        bool open;
    }

    mapping(uint256 => Position) public positions;

    event PositionOpened(uint256 indexed id, address indexed trader, PositionType positionType, uint256 amount, uint256 entryPrice, uint256 collateral);
    event PositionClosed(uint256 indexed id, address indexed trader, uint256 exitPrice, int256 profitOrLoss);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor(uint256 _initialPrice) {
        owner = msg.sender;
        currentPrice = _initialPrice;
    }

    // Allow owner to update current market price
    function updatePrice(uint256 newPrice) external onlyOwner {
        currentPrice = newPrice;
    }

    /// @notice Open a new isolated margin position by depositing collateral (in Ether).
    /// @param posType The type of position: 0 for Long, 1 for Short.
    /// @param amount The position size (e.g., number of coins).
    function openPosition(PositionType posType, uint256 amount) external payable {
        require(msg.value > 0, "Collateral required");
        positions[nextPositionId] = Position({
            id: nextPositionId,
            trader: msg.sender,
            positionType: posType,
            amount: amount,
            entryPrice: currentPrice,
            collateral: msg.value,
            open: true
        });
        emit PositionOpened(nextPositionId, msg.sender, posType, amount, currentPrice, msg.value);
        nextPositionId++;
    }

    /// @notice Close an open position and calculate profit or loss.
    /// @param positionId The ID of the position to close.
    function closePosition(uint256 positionId) external {
        Position storage pos = positions[positionId];
        require(pos.open, "Position already closed");
        require(pos.trader == msg.sender, "Not your position");
        pos.open = false;
        uint256 exitPrice = currentPrice;
        int256 profitOrLoss;
        if (pos.positionType == PositionType.Long) {
            profitOrLoss = int256(exitPrice) - int256(pos.entryPrice);
            profitOrLoss = profitOrLoss * int256(pos.amount);
        } else {
            profitOrLoss = int256(pos.entryPrice) - int256(exitPrice);
            profitOrLoss = profitOrLoss * int256(pos.amount);
        }
        // In a real implementation, collateral adjustments, fees, and liquidation logic would be handled here.
        // For demonstration, simply refund the collateral.
        payable(pos.trader).transfer(pos.collateral);
        emit PositionClosed(positionId, pos.trader, exitPrice, profitOrLoss);
    }
}
