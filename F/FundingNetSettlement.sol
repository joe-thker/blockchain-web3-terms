// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FundingNetSettlement {
    struct Position {
        uint256 size;
        bool isLong;
    }

    mapping(address => Position) public positions;
    address[] public participants;

    uint256 public globalFundingRate; // 1e6 = 1%
    uint256 public totalLong;
    uint256 public totalShort;
    uint256 public fundingInterval = 8 hours;
    uint256 public lastSettlement;

    mapping(address => uint256) public payouts;

    function openPosition(uint256 size, bool isLong) external {
        positions[msg.sender] = Position(size, isLong);
        participants.push(msg.sender);
        if (isLong) totalLong += size;
        else totalShort += size;
    }

    function setFundingRate(uint256 rate) external {
        globalFundingRate = rate;
    }

    function settle() external {
        require(block.timestamp >= lastSettlement + fundingInterval, "Too early");

        uint256 totalTransfer = (totalLong * globalFundingRate) / 1e6;

        for (uint256 i = 0; i < participants.length; i++) {
            address user = participants[i];
            Position memory p = positions[user];

            if (p.isLong) {
                payouts[user] -= (p.size * globalFundingRate) / 1e6;
            } else {
                payouts[user] += (p.size * globalFundingRate * totalLong) / (1e6 * totalShort);
            }
        }

        lastSettlement = block.timestamp;
    }

    function getPayout(address user) external view returns (int256) {
        return int256(payouts[user]);
    }
}
