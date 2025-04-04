pragma solidity ^0.8.20;

contract TokenGenesis {
    mapping(address => uint256) public allocations;
    uint256 public totalAllocated;

    constructor(address[] memory recipients, uint256[] memory amounts) {
        require(recipients.length == amounts.length, "Mismatch");
        for (uint i = 0; i < recipients.length; i++) {
            allocations[recipients[i]] = amounts[i];
            totalAllocated += amounts[i];
        }
    }
}
