// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FundingMarketSkew {
    uint256 public longOpenInterest;
    uint256 public shortOpenInterest;
    uint256 public fundingInterval = 8 hours;
    uint256 public lastFundingTimestamp;

    struct Position {
        uint256 size;
        bool isLong;
        uint256 fundingAccrued;
    }

    mapping(address => Position) public positions;

    function openPosition(uint256 size, bool isLong) external {
        positions[msg.sender] = Position(size, isLong, 0);
        if (isLong) longOpenInterest += size;
        else shortOpenInterest += size;
    }

    function applyFunding(address user) external {
        require(block.timestamp >= lastFundingTimestamp + fundingInterval, "Too soon");

        Position storage pos = positions[user];
        require(pos.size > 0, "No position");

        int256 imbalance = int256(longOpenInterest) - int256(shortOpenInterest);
        int256 rate = (imbalance * 1e6) / int256(longOpenInterest + shortOpenInterest + 1);

        int256 funding = int256(pos.size) * rate / 1e6;

        if (pos.isLong && funding > 0) {
            pos.fundingAccrued += uint256(funding);
        } else if (!pos.isLong && funding < 0) {
            pos.fundingAccrued += uint256(-funding);
        }

        lastFundingTimestamp = block.timestamp;
    }

    function getAccrued(address user) external view returns (uint256) {
        return positions[user].fundingAccrued;
    }
}
