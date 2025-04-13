// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FusionRollupDA {
    address public operator;

    struct DACommitment {
        bytes32 blobHash;
        bytes32 dataRoot;
        uint256 timestamp;
    }

    mapping(uint256 => DACommitment) public commitments;
    uint256 public batchId;

    event DAAnchored(uint256 indexed id, bytes32 blobHash, bytes32 root);

    constructor(address _operator) {
        operator = _operator;
    }

    function anchorData(bytes32 blobHash, bytes32 root) external {
        require(msg.sender == operator, "Only operator");
        batchId++;
        commitments[batchId] = DACommitment(blobHash, root, block.timestamp);
        emit DAAnchored(batchId, blobHash, root);
    }
}
