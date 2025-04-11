// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FomoLastBuyer {
    address public lastBuyer;
    uint256 public lastBuyTime;
    uint256 public duration = 5 minutes;
    uint256 public pot;
    bool public ended;

    event Buy(address indexed player, uint256 value);
    event Won(address indexed winner, uint256 amount);

    function buy() public payable {
        require(!ended, "Game over");
        require(msg.value > 0, "Send ETH");

        lastBuyer = msg.sender;
        lastBuyTime = block.timestamp;
        pot += msg.value;

        emit Buy(msg.sender, msg.value);
    }

    function claim() external {
        require(block.timestamp >= lastBuyTime + duration, "Not yet");
        require(msg.sender == lastBuyer, "Not winner");
        require(!ended, "Already claimed");

        ended = true;
        uint256 payout = pot;
        pot = 0;

        (bool sent, ) = payable(msg.sender).call{value: payout}("");
        require(sent, "Fail");
        emit Won(msg.sender, payout);
    }

    receive() external payable {
        buy();
    }
}
