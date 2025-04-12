// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MEVReorgFraudProof {
    mapping(uint256 => bytes32) public proposedBlocks;
    mapping(uint256 => bool) public disputed;

    event BlockProposed(uint256 height, bytes32 blockHash);
    event ReorgFraud(uint256 height, bytes32 invalidHash, address slasher);

    function proposeBlock(uint256 height, bytes32 hash) external {
        require(proposedBlocks[height] == bytes32(0), "Block exists");
        proposedBlocks[height] = hash;
        emit BlockProposed(height, hash);
    }

    function slashReorg(uint256 height, bytes32 conflictingHash) external {
        require(proposedBlocks[height] != conflictingHash, "Not reorg");
        require(!disputed[height], "Already disputed");

        disputed[height] = true;
        emit ReorgFraud(height, conflictingHash, msg.sender);
        // Optional: slash proposer
    }
}
