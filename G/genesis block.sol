// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simulated Genesis Block Registry
contract GenesisBlock {
    address public creator;
    uint256 public timestamp;
    bytes32 public genesisHash;

    mapping(address => uint256) public initialAllocations;
    address[] public participants;

    event GenesisInitialized(address indexed creator, uint256 timestamp, bytes32 hash);
    event AllocationSet(address indexed user, uint256 amount);

    constructor(address[] memory users, uint256[] memory amounts) {
        require(users.length == amounts.length, "Mismatch");
        creator = msg.sender;
        timestamp = block.timestamp;
        genesisHash = keccak256(abi.encodePacked(block.timestamp, msg.sender));

        for (uint256 i = 0; i < users.length; i++) {
            initialAllocations[users[i]] = amounts[i];
            participants.push(users[i]);
            emit AllocationSet(users[i], amounts[i]);
        }

        emit GenesisInitialized(creator, timestamp, genesisHash);
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    function getAllocation(address user) external view returns (uint256) {
        return initialAllocations[user];
    }
}
