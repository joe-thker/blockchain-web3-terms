// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FuturesInverse {
    address public owner;
    uint256 public initialPrice;
    uint256 public settlementPrice;
    bool public settled;

    enum Side { None, Long, Short }

    struct Position {
        Side side;
        uint256 collateral;
        bool claimed;
    }

    mapping(address => Position) public positions;

    constructor(uint256 _initialPrice) {
        owner = msg.sender;
        initialPrice = _initialPrice;
    }

    function open(Side side) external payable {
        require(msg.value > 0 && positions[msg.sender].side == Side.None);
        positions[msg.sender] = Position(side, msg.value, false);
    }

    function settle(uint256 _settlementPrice) external {
        require(msg.sender == owner && !settled);
        settlementPrice = _settlementPrice;
        settled = true;
    }

    function claim() external {
        require(settled);
        Position storage p = positions[msg.sender];
        require(!p.claimed);

        uint256 payout = 0;
        if (p.side == Side.Long) {
            payout = (p.collateral * settlementPrice) / initialPrice;
        } else if (p.side == Side.Short) {
            payout = (p.collateral * initialPrice) / settlementPrice;
        }

        p.claimed = true;
        payable(msg.sender).transfer(payout);
    }

    receive() external payable {}
}
