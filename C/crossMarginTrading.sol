// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CrossMarginTrading {
    enum PositionType { Long, Short }
    uint256 public nextPositionId;
    address public owner;
    uint256 public currentPrice;

    struct Position {
        uint256 id;
        address trader;
        PositionType positionType;
        uint256 amount;
        uint256 entryPrice;
        bool open;
    }

    mapping(uint256 => Position) public positions;
    // Collateral per trader is pooled across all positions.
    mapping(address => uint256) public traderCollateral;

    event CollateralDeposited(address indexed trader, uint256 amount);
    event PositionOpened(uint256 indexed id, address indexed trader, PositionType positionType, uint256 amount, uint256 entryPrice);
    event PositionClosed(uint256 indexed id, address indexed trader, uint256 exitPrice, int256 profitOrLoss);
    event CollateralWithdrawn(address indexed trader, uint256 amount);

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

    /// @notice Deposit collateral for margin trading.
    function depositCollateral() external payable {
        require(msg.value > 0, "Must deposit > 0 Ether");
        traderCollateral[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    /// @notice Withdraw collateral (only allowed if no open positions for simplicity).
    function withdrawCollateral(uint256 amount) external {
        require(traderCollateral[msg.sender] >= amount, "Insufficient collateral");
        // In a full implementation, you would check for open positions.
        traderCollateral[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    /// @notice Open a cross margin position using shared collateral.
    function openPosition(PositionType posType, uint256 amount) external {
        require(traderCollateral[msg.sender] > 0, "No collateral deposited");
        positions[nextPositionId] = Position({
            id: nextPositionId,
            trader: msg.sender,
            positionType: posType,
            amount: amount,
            entryPrice: currentPrice,
            open: true
        });
        emit PositionOpened(nextPositionId, msg.sender, posType, amount, currentPrice);
        nextPositionId++;
    }

    /// @notice Close an open position.
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
        // In a real system, PnL settlement would affect trader's collateral.
        emit PositionClosed(positionId, pos.trader, exitPrice, profitOrLoss);
    }
}
