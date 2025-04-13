// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simple Futures Market
/// @notice Supports long/short positions with settlement via mock oracle

contract FuturesMarket {
    address public owner;
    uint256 public initialPrice;
    uint256 public settlementPrice;
    bool public settled;

    enum PositionType { None, Long, Short }

    struct Position {
        PositionType positionType;
        uint256 margin;
        bool claimed;
    }

    mapping(address => Position) public positions;

    event PositionOpened(address indexed trader, PositionType posType, uint256 margin);
    event Settled(uint256 price);
    event Claimed(address indexed trader, uint256 payout);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notSettled() {
        require(!settled, "Already settled");
        _;
    }

    constructor(uint256 _initialPrice) {
        owner = msg.sender;
        initialPrice = _initialPrice;
    }

    function openLong() external payable notSettled {
        require(msg.value > 0, "Margin required");
        require(positions[msg.sender].positionType == PositionType.None, "Already opened");

        positions[msg.sender] = Position(PositionType.Long, msg.value, false);
        emit PositionOpened(msg.sender, PositionType.Long, msg.value);
    }

    function openShort() external payable notSettled {
        require(msg.value > 0, "Margin required");
        require(positions[msg.sender].positionType == PositionType.None, "Already opened");

        positions[msg.sender] = Position(PositionType.Short, msg.value, false);
        emit PositionOpened(msg.sender, PositionType.Short, msg.value);
    }

    /// @notice Settles market based on off-chain price feed (mocked here)
    function settleMarket(uint256 _settlementPrice) external onlyOwner notSettled {
        settlementPrice = _settlementPrice;
        settled = true;
        emit Settled(settlementPrice);
    }

    /// @notice Claim profit/loss after market settles
    function claim() external {
        require(settled, "Not settled");
        Position storage pos = positions[msg.sender];
        require(pos.positionType != PositionType.None, "No position");
        require(!pos.claimed, "Already claimed");

        uint256 payout = pos.margin;
        if (pos.positionType == PositionType.Long) {
            if (settlementPrice > initialPrice) {
                uint256 pnl = (settlementPrice - initialPrice) * pos.margin / initialPrice;
                payout += pnl;
            } else {
                uint256 loss = (initialPrice - settlementPrice) * pos.margin / initialPrice;
                payout = pos.margin > loss ? pos.margin - loss : 0;
            }
        } else if (pos.positionType == PositionType.Short) {
            if (settlementPrice < initialPrice) {
                uint256 pnl = (initialPrice - settlementPrice) * pos.margin / initialPrice;
                payout += pnl;
            } else {
                uint256 loss = (settlementPrice - initialPrice) * pos.margin / initialPrice;
                payout = pos.margin > loss ? pos.margin - loss : 0;
            }
        }

        pos.claimed = true;
        payable(msg.sender).transfer(payout);
        emit Claimed(msg.sender, payout);
    }

    function getMyPosition() external view returns (PositionType, uint256, bool) {
        Position memory p = positions[msg.sender];
        return (p.positionType, p.margin, p.claimed);
    }

    function getMarketStatus() external view returns (bool, uint256, uint256) {
        return (settled, initialPrice, settlementPrice);
    }

    receive() external payable {}
}
