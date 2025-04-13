// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FuturesPerpetual {
    address public owner;
    int256 public fundingRate; // e.g., 100 = 0.01%
    uint256 public lastFundingTime;
    uint256 public fundingInterval = 8 hours;

    struct Trader {
        bool isLong;
        uint256 margin;
        uint256 accruedFunding;
    }

    mapping(address => Trader) public traders;

    constructor() {
        owner = msg.sender;
        lastFundingTime = block.timestamp;
    }

    function setFundingRate(int256 rate) external {
        require(msg.sender == owner);
        fundingRate = rate;
    }

    function openPosition(bool isLong) external payable {
        require(msg.value > 0);
        traders[msg.sender] = Trader(isLong, msg.value, 0);
    }

    function applyFunding(address user) external {
        require(block.timestamp >= lastFundingTime + fundingInterval);
        Trader storage t = traders[user];
        int256 funding = int256(t.margin) * fundingRate / 1e6;

        if (t.isLong && funding > 0) {
            t.accruedFunding += uint256(funding);
        } else if (!t.isLong && funding < 0) {
            t.accruedFunding += uint256(-funding);
        }

        lastFundingTime = block.timestamp;
    }

    function claimFunding() external {
        uint256 payout = traders[msg.sender].accruedFunding;
        traders[msg.sender].accruedFunding = 0;
        payable(msg.sender).transfer(payout);
    }

    receive() external payable {}
}
