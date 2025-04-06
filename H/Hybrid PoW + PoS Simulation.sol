// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Hybrid PoW/PoS Consensus Simulator
contract HybridPoWPoS {
    uint256 public difficulty = 2**240; // Lower = harder
    uint256 public stakeRequirement = 1 ether;

    struct BlockCandidate {
        address miner;
        uint256 nonce;
        bytes32 hash;
        bool approved;
        uint256 approvals;
    }

    mapping(uint256 => BlockCandidate) public proposedBlocks;
    mapping(address => uint256) public stakes;
    mapping(uint256 => mapping(address => bool)) public voted;

    uint256 public blockHeight;

    event BlockMined(uint256 height, address miner, bytes32 hash);
    event BlockApproved(uint256 height, address validator);

    /// @notice Stake ETH to become a validator
    function stake() external payable {
        require(msg.value >= stakeRequirement, "Minimum 1 ETH required");
        stakes[msg.sender] += msg.value;
    }

    /// @notice PoW mining simulation (off-chain miners submit solution)
    function mineBlock(uint256 nonce) external {
        bytes32 blockHash = keccak256(abi.encodePacked(msg.sender, blockHeight, nonce));
        require(uint256(blockHash) < difficulty, "Hash does not meet difficulty");

        proposedBlocks[blockHeight] = BlockCandidate({
            miner: msg.sender,
            nonce: nonce,
            hash: blockHash,
            approved: false,
            approvals: 0
        });

        emit BlockMined(blockHeight, msg.sender, blockHash);
    }

    /// @notice PoS validator votes to approve mined block
    function approveBlock() external {
        require(stakes[msg.sender] >= stakeRequirement, "Not a validator");
        require(!voted[blockHeight][msg.sender], "Already voted");

        BlockCandidate storage blk = proposedBlocks[blockHeight];
        require(blk.miner != address(0), "No block to approve");

        blk.approvals += 1;
        voted[blockHeight][msg.sender] = true;

        emit BlockApproved(blockHeight, msg.sender);

        // Finalize block if approvals >= 3 (demo threshold)
        if (blk.approvals >= 3) {
            blk.approved = true;
            blockHeight += 1; // Finalize block
        }
    }

    function getBlock(uint256 height) external view returns (
        address miner, bytes32 hash, bool approved, uint256 votes
    ) {
        BlockCandidate memory blk = proposedBlocks[height];
        return (blk.miner, blk.hash, blk.approved, blk.approvals);
    }
}
