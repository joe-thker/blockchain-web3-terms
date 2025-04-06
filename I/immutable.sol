// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ImmutableExample {
    address public immutable owner;
    uint256 public immutable createdAt;

    constructor() {
        owner = msg.sender;
        createdAt = block.timestamp;
    }

    function getInfo() external view returns (address, uint256) {
        return (owner, createdAt);
    }
}
