// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOracle {
    function getSpotPrice() external view returns (uint256);
    function getPerpPrice() external view returns (uint256);
}

contract FundingOracleBased {
    IOracle public oracle;
    uint256 public fundingInterval = 8 hours;
    uint256 public lastFundingTimestamp;

    struct Position {
        uint256 size;
        bool isLong;
        uint256 accruedFunding;
    }

    mapping(address => Position) public positions;

    constructor(address oracleAddr) {
        oracle = IOracle(oracleAddr);
        lastFundingTimestamp = block.timestamp;
    }

    function openPosition(uint256 size, bool isLong) external {
        positions[msg.sender] = Position(size, isLong, 0);
    }

    function applyFunding(address user) external {
        require(block.timestamp >= lastFundingTimestamp + fundingInterval, "Too soon");

        uint256 perp = oracle.getPerpPrice();
        uint256 spot = oracle.getSpotPrice();
        int256 diff = int256(perp) - int256(spot);
        int256 rate = (diff * 1e6) / int256(spot); // scaled

        Position storage pos = positions[user];
        require(pos.size > 0, "No position");

        int256 payment = int256(pos.size) * rate / 1e6;

        if (pos.isLong && payment > 0) {
            pos.accruedFunding += uint256(payment);
        } else if (!pos.isLong && payment < 0) {
            pos.accruedFunding += uint256(-payment);
        }

        lastFundingTimestamp = block.timestamp;
    }

    function getAccrued(address user) external view returns (uint256) {
        return positions[user].accruedFunding;
    }
}
