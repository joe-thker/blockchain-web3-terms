// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ForkChoiceLongestChain {
    struct Fork {
        string name;
        uint256 blockCount;
        bool exists;
    }

    mapping(bytes32 => Fork) public forks;
    bytes32 public canonicalFork;

    event ForkAdded(bytes32 indexed forkId, string name);
    event BlockAdded(bytes32 indexed forkId, uint256 newHeight);
    event CanonicalUpdated(bytes32 indexed forkId);

    function addFork(string calldata name) external returns (bytes32 forkId) {
        forkId = keccak256(abi.encodePacked(name, block.timestamp));
        forks[forkId] = Fork(name, 0, true);
        emit ForkAdded(forkId, name);
    }

    function addBlock(bytes32 forkId) external {
        require(forks[forkId].exists, "No fork");
        forks[forkId].blockCount++;

        if (forks[forkId].blockCount > forks[canonicalFork].blockCount) {
            canonicalFork = forkId;
            emit CanonicalUpdated(forkId);
        }

        emit BlockAdded(forkId, forks[forkId].blockCount);
    }

    function getCanonical() external view returns (string memory) {
        return forks[canonicalFork].name;
    }
}
