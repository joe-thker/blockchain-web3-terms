// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FUDsterArena {
    struct Bet {
        uint256 amount;
        uint256 boost;
        bool claimed;
    }

    mapping(address => Bet) public bets;
    uint256 public totalPool;
    uint256 public gameEnd;
    address public owner;

    modifier onlyBeforeEnd() {
        require(block.timestamp < gameEnd, "Game ended");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= gameEnd, "Game not ended");
        _;
    }

    constructor(uint256 duration) {
        owner = msg.sender;
        gameEnd = block.timestamp + duration;
    }

    function placeBet() external payable onlyBeforeEnd {
        require(msg.value > 0, "No ETH sent");
        bets[msg.sender].amount += msg.value;
        totalPool += msg.value;
    }

    function spreadFUD() external onlyBeforeEnd {
        bets[msg.sender].boost += 5;
    }

    function claimReward() external onlyAfterEnd {
        Bet storage b = bets[msg.sender];
        require(!b.claimed && b.amount > 0, "Invalid claim");
        b.claimed = true;

        uint256 reward = b.amount + (b.boost * 1e15); // 0.001 ETH per FUD point
        payable(msg.sender).transfer(reward);
    }

    receive() external payable {}
}
