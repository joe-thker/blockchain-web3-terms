// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CrossMarginTrading is ReentrancyGuard {
    // Enumeration for position type.
    enum PositionType { Long, Short }
    
    // Next available position ID.
    uint256 public nextPositionId;
    // Owner (administrator) of the contract.
    address public owner;
    // Current market price (this would normally be provided by an oracle).
    uint256 public currentPrice;

    // Structure representing a margin position.
    struct Position {
        uint256 id;
        address trader;
        PositionType positionType;
        uint256 amount;      // Quantity of asset in the position.
        uint256 entryPrice;  // Market price when the position was opened.
        bool open;
    }
    
    // Mapping of position ID to Position details.
    mapping(uint256 => Position) public positions;
    // Mapping of trader addresses to their total deposited collateral (in wei).
    mapping(address => uint256) public traderCollateral;

    // Events for logging collateral deposits/withdrawals, position opening/closing, and price updates.
    event CollateralDeposited(address indexed trader, uint256 amount);
    event CollateralWithdrawn(address indexed trader, uint256 amount);
    event PositionOpened(uint256 indexed id, address indexed trader, PositionType positionType, uint256 amount, uint256 entryPrice);
    event PositionClosed(uint256 indexed id, address indexed trader, uint256 exitPrice, int256 profitOrLoss);
    event PriceUpdated(uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }
    
    constructor(uint256 _initialPrice) {
        owner = msg.sender;
        currentPrice = _initialPrice;
    }

    /// @notice Allows the owner to update the current market price.
    /// @param newPrice The updated market price.
    function updatePrice(uint256 newPrice) external onlyOwner {
        currentPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    /// @notice Deposit collateral into the trading account.
    /// @dev Collateral is stored as Ether.
    function depositCollateral() external payable nonReentrant {
        require(msg.value > 0, "Must deposit > 0 Ether");
        traderCollateral[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    /// @notice Withdraw collateral if no open positions (or if collateralization requirements are met).
    /// @param amount The amount of Ether to withdraw.
    function withdrawCollateral(uint256 amount) external nonReentrant {
        require(traderCollateral[msg.sender] >= amount, "Insufficient collateral");
        // For simplicity, we assume the trader can withdraw collateral if they have sufficient funds.
        // In a full implementation, open positions would be checked to ensure proper collateralization.
        traderCollateral[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        emit CollateralWithdrawn(msg.sender, amount);
    }

    /// @notice Open a new margin position using the trader's collateral.
    /// @param posType The type of position: 0 for Long, 1 for Short.
    /// @param amount The quantity of the asset in the position.
    function openPosition(PositionType posType, uint256 amount) external {
        require(traderCollateral[msg.sender] > 0, "No collateral deposited");
        // In a production contract, collateralization checks would limit the maximum borrowable amount.
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

    /// @notice Close an open margin position and calculate profit or loss.
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
        
        emit PositionClosed(positionId, msg.sender, exitPrice, profitOrLoss);
        // In a full implementation, profit/loss would affect the trader's collateral balance.
    }

    /// @notice Retrieves details of a specific position.
    /// @param positionId The ID of the position.
    /// @return The Position struct.
    function getPosition(uint256 positionId) external view returns (Position memory) {
        return positions[positionId];
    }
}
