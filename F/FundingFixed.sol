// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FundingFixed {
    address public owner;
    int256 public fundingRate; // scaled: 1e6 = 1%
    uint256 public fundingInterval = 8 hours;
    uint256 public lastFundingTimestamp;

    struct Position {
        uint256 size;
        bool isLong;
        uint256 accruedFunding;
    }

    mapping(address => Position) public positions;

    event FundingApplied(address user, int256 funding);

    constructor() {
        owner = msg.sender;
        lastFundingTimestamp = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function setFundingRate(int256 _rate) external onlyOwner {
        require(_rate >= -1e6 && _rate <= 1e6, "Out of bounds");
        fundingRate = _rate;
    }

    function openPosition(uint256 size, bool isLong) external {
        require(size > 0, "Invalid size");
        positions[msg.sender] = Position(size, isLong, 0);
    }

    function applyFunding(address user) external {
        require(block.timestamp >= lastFundingTimestamp + fundingInterval, "Too early");

        Position storage pos = positions[user];
        require(pos.size > 0, "No position");

        int256 payment = int256(pos.size) * fundingRate / 1e6;

        if (pos.isLong && payment > 0) {
            pos.accruedFunding += uint256(payment);
        } else if (!pos.isLong && payment < 0) {
            pos.accruedFunding += uint256(-payment);
        }

        lastFundingTimestamp = block.timestamp;
        emit FundingApplied(user, payment);
    }

    function getAccruedFunding(address user) external view returns (uint256) {
        return positions[user].accruedFunding;
    }
}
