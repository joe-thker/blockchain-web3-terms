// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FuturesLinear {
    uint256 public price; // oracle feed placeholder
    address public owner;

    enum Position { None, Long, Short }

    struct Trade {
        Position position;
        uint256 margin;
        bool settled;
    }

    mapping(address => Trade) public trades;
    bool public isSettled;
    uint256 public settlementPrice;

    constructor(uint256 _price) {
        owner = msg.sender;
        price = _price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function openLong() external payable {
        require(trades[msg.sender].position == Position.None, "Already active");
        trades[msg.sender] = Trade(Position.Long, msg.value, false);
    }

    function openShort() external payable {
        require(trades[msg.sender].position == Position.None, "Already active");
        trades[msg.sender] = Trade(Position.Short, msg.value, false);
    }

    function settle(uint256 _settlementPrice) external onlyOwner {
        require(!isSettled, "Already settled");
        settlementPrice = _settlementPrice;
        isSettled = true;
    }

    function claim() external {
        Trade storage t = trades[msg.sender];
        require(isSettled && !t.settled, "Not eligible");

        uint256 payout = t.margin;

        if (t.position == Position.Long) {
            if (settlementPrice > price) {
                payout += ((settlementPrice - price) * t.margin) / price;
            } else {
                uint256 loss = ((price - settlementPrice) * t.margin) / price;
                payout = payout > loss ? payout - loss : 0;
            }
        }

        if (t.position == Position.Short) {
            if (settlementPrice < price) {
                payout += ((price - settlementPrice) * t.margin) / price;
            } else {
                uint256 loss = ((settlementPrice - price) * t.margin) / price;
                payout = payout > loss ? payout - loss : 0;
            }
        }

        t.settled = true;
        payable(msg.sender).transfer(payout);
    }

    receive() external payable {}
}
