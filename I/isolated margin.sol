// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract IsolatedMarginTrading {
    struct Position {
        address trader;
        uint256 margin;      // ETH deposited as margin
        uint256 size;        // Size of the leveraged position
        uint256 entryPrice;  // Entry price (simulated)
        bool open;
    }

    uint256 public constant LEVERAGE = 5;
    uint256 public constant LIQUIDATION_THRESHOLD = 80; // e.g. 80% loss triggers liquidation

    uint256 public positionId;
    mapping(uint256 => Position) public positions;

    event Opened(uint256 id, address trader, uint256 margin, uint256 size, uint256 entryPrice);
    event Closed(uint256 id, uint256 pnl, bool liquidated);

    function openPosition(uint256 entryPrice) external payable {
        require(msg.value > 0, "No margin sent");
        uint256 size = msg.value * LEVERAGE;

        positions[positionId] = Position({
            trader: msg.sender,
            margin: msg.value,
            size: size,
            entryPrice: entryPrice,
            open: true
        });

        emit Opened(positionId, msg.sender, msg.value, size, entryPrice);
        positionId++;
    }

    function closePosition(uint256 id, uint256 exitPrice) external {
        Position storage pos = positions[id];
        require(pos.trader == msg.sender, "Not your position");
        require(pos.open, "Already closed");

        uint256 pnl;
        bool liquidated = false;

        if (exitPrice < pos.entryPrice) {
            uint256 loss = ((pos.entryPrice - exitPrice) * pos.size) / pos.entryPrice;
            if (loss >= (pos.margin * LIQUIDATION_THRESHOLD) / 100) {
                liquidated = true;
                pnl = 0;
            } else {
                pnl = pos.margin - loss;
            }
        } else {
            pnl = pos.margin + ((exitPrice - pos.entryPrice) * pos.size) / pos.entryPrice;
        }

        pos.open = false;
        emit Closed(id, pnl, liquidated);

        if (!liquidated) {
            payable(msg.sender).transfer(pnl);
        }
    }

    receive() external payable {}
}
