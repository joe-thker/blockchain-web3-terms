// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EthashSim {
    uint256 public difficulty;
    bytes32 public lastBlockHash;
    address public lastMiner;

    event NewProof(address indexed miner, bytes32 hash, uint256 nonce);

    constructor(uint256 _difficulty) {
        difficulty = _difficulty;
        lastBlockHash = keccak256(abi.encodePacked(block.timestamp));
    }

    function submitProof(uint256 nonce) external {
        bytes32 hash = keccak256(abi.encodePacked(lastBlockHash, msg.sender, nonce));
        require(uint256(hash) < difficulty, "Invalid proof of work");

        lastBlockHash = hash;
        lastMiner = msg.sender;

        emit NewProof(msg.sender, hash, nonce);
    }

    function setDifficulty(uint256 _difficulty) external {
        // In real use, restricted to admin or governance
        difficulty = _difficulty;
    }
}
