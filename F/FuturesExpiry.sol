// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FuturesExpiry {
    address public owner;
    uint256 public expiryTimestamp;
    uint256 public priceAtExpiry;
    bool public settled;

    mapping(address => uint256) public longs;
    mapping(address => uint256) public shorts;

    constructor(uint256 _expiryTimestamp) {
        owner = msg.sender;
        expiryTimestamp = _expiryTimestamp;
    }

    function openLong() external payable {
        require(block.timestamp < expiryTimestamp);
        longs[msg.sender] += msg.value;
    }

    function openShort() external payable {
        require(block.timestamp < expiryTimestamp);
        shorts[msg.sender] += msg.value;
    }

    function settle(uint256 _price) external {
        require(msg.sender == owner && block.timestamp >= expiryTimestamp && !settled);
        priceAtExpiry = _price;
        settled = true;
    }

    function claimLong() external {
        require(settled);
        uint256 margin = longs[msg.sender];
        require(margin > 0);
        longs[msg.sender] = 0;
        payable(msg.sender).transfer(margin); // real logic would adjust PnL
    }

    function claimShort() external {
        require(settled);
        uint256 margin = shorts[msg.sender];
        require(margin > 0);
        shorts[msg.sender] = 0;
        payable(msg.sender).transfer(margin);
    }

    receive() external payable {}
}
