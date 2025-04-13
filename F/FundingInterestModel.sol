// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FundingInterestModel {
    uint256 public interestRate; // scaled: 1e6 = 1% annual
    uint256 public lastUpdate;

    struct Position {
        uint256 size;
        uint256 accrued;
        uint256 entryTimestamp;
    }

    mapping(address => Position) public positions;

    constructor(uint256 _rate) {
        interestRate = _rate;
        lastUpdate = block.timestamp;
    }

    function openPosition(uint256 size) external {
        positions[msg.sender] = Position(size, 0, block.timestamp);
    }

    function accrueInterest(address user) external {
        Position storage p = positions[user];
        require(p.size > 0, "No position");

        uint256 duration = block.timestamp - p.entryTimestamp;
        uint256 accrued = (p.size * interestRate * duration) / (365 days * 1e6);

        p.accrued += accrued;
        p.entryTimestamp = block.timestamp;
    }

    function getAccrued(address user) external view returns (uint256) {
        return positions[user].accrued;
    }
}
