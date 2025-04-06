// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ImmutableOwner {
    address public immutable owner;
    uint256 public immutable deployBlock;

    constructor() {
        owner = msg.sender;
        deployBlock = block.number;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
