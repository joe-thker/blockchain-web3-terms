// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HybridSequential {
    uint256 public difficulty = 2**240;
    uint256 public blockHeight;

    struct BlockCandidate {
        address miner;
        uint256 nonce;
        bytes32 hash;
        uint256 votes;
        bool finalized;
    }

    mapping(uint256 => BlockCandidate) public candidates;
    mapping(address => uint256) public stakes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    function stake() external payable {
        require(msg.value >= 1 ether);
        stakes[msg.sender] += msg.value;
    }

    function mine(uint256 nonce) external {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, blockHeight, nonce));
        require(uint256(hash) < difficulty, "Invalid PoW");
        candidates[blockHeight] = BlockCandidate(msg.sender, nonce, hash, 0, false);
    }

    function vote() external {
        BlockCandidate storage blk = candidates[blockHeight];
        require(stakes[msg.sender] > 0, "Not a validator");
        require(!hasVoted[blockHeight][msg.sender], "Already voted");
        require(blk.miner != address(0), "No block");

        blk.votes += 1;
        hasVoted[blockHeight][msg.sender] = true;

        if (blk.votes >= 3) {
            blk.finalized = true;
            blockHeight += 1;
        }
    }
}
