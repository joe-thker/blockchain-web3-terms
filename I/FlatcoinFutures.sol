// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FlatcoinFutures {
    struct Position {
        uint256 size;
        uint256 entryPrice;
        bool long;
    }

    mapping(address => Position) public positions;
    uint256 public futureCPI = 11000; // Expected CPI

    function openPosition(uint256 size, bool long) external {
        require(positions[msg.sender].size == 0, "Already open");
        positions[msg.sender] = Position(size, futureCPI, long);
    }

    function closePosition() external {
        Position memory pos = positions[msg.sender];
        require(pos.size > 0, "None");

        bool win = (pos.long && futureCPI > pos.entryPrice) ||
                   (!pos.long && futureCPI < pos.entryPrice);

        delete positions[msg.sender];
        if (win) payable(msg.sender).transfer(1 ether); // mock payout
    }

    receive() external payable {}
}
