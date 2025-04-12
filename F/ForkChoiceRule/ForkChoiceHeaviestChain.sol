// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ForkChoiceHeaviestChain {
    struct Fork {
        string name;
        uint256 weight;
        bool exists;
    }

    mapping(bytes32 => Fork) public forks;
    bytes32 public canonicalFork;

    event ForkRegistered(bytes32 indexed id, string name);
    event Voted(bytes32 indexed id, uint256 amount);
    event CanonicalUpdated(bytes32 indexed id);

    function registerFork(string memory name) external returns (bytes32 forkId) {
        forkId = keccak256(abi.encodePacked(name, block.timestamp));
        forks[forkId] = Fork(name, 0, true);
        emit ForkRegistered(forkId, name);
    }

    function vote(bytes32 forkId) external payable {
        require(forks[forkId].exists, "Fork doesn't exist");
        require(msg.value > 0, "Need to vote with ETH");

        forks[forkId].weight += msg.value;
        emit Voted(forkId, msg.value);

        if (forks[forkId].weight > forks[canonicalFork].weight) {
            canonicalFork = forkId;
            emit CanonicalUpdated(forkId);
        }
    }

    function getCanonical() external view returns (string memory) {
        return forks[canonicalFork].name;
    }
}
