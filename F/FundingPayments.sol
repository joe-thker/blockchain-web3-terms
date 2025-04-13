// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FundingPayments {
    address public owner;
    int256 public fundingRate;         // scaled by 1e6 (e.g., 0.01% = 100)
    uint256 public lastFundingTimestamp;
    uint256 public fundingInterval = 8 hours;

    struct Position {
        uint256 size;       // in USD
        bool isLong;        // true for long, false for short
        uint256 fundingAccrued;
    }

    mapping(address => Position) public positions;

    event FundingRateUpdated(int256 newRate);
    event FundingApplied(address user, int256 payment);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        lastFundingTimestamp = block.timestamp;
    }

    /// Admin sets the funding rate, e.g. 100 = 0.01%, -250 = -0.025%
    function setFundingRate(int256 _rate) external onlyOwner {
        require(_rate > -1e6 && _rate < 1e6, "Invalid rate");
        fundingRate = _rate;
        emit FundingRateUpdated(_rate);
    }

    /// Open a position (mocked without margin logic)
    function openPosition(uint256 size, bool isLong) external {
        require(size > 0, "Invalid size");
        positions[msg.sender] = Position(size, isLong, 0);
    }

    /// Apply funding to an individual trader
    function applyFunding(address trader) external {
        Position storage pos = positions[trader];
        require(pos.size > 0, "No position");

        require(block.timestamp >= lastFundingTimestamp + fundingInterval, "Too soon");

        // Funding payment = size * rate / 1e6
        int256 payment = int256(pos.size) * fundingRate / 1e6;

        if (pos.isLong && payment > 0) {
            pos.fundingAccrued += uint256(payment);
        } else if (!pos.isLong && payment < 0) {
            pos.fundingAccrued += uint256(-payment);
        }

        lastFundingTimestamp = block.timestamp;
        emit FundingApplied(trader, payment);
    }

    function getFundingAccrued(address trader) external view returns (uint256) {
        return positions[trader].fundingAccrued;
    }
}
