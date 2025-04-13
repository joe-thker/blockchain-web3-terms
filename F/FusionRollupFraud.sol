// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FusionRollupFraud {
    address public operator;
    uint256 public challengeWindow = 1 days;

    struct Batch {
        bytes32 root;
        uint256 timestamp;
        bool challenged;
    }

    mapping(uint256 => Batch) public batches;
    uint256 public batchId;

    event Submitted(uint256 batchId, bytes32 root);
    event Challenged(uint256 batchId);

    constructor(address _operator) {
        operator = _operator;
    }

    function submit(bytes32 root) external {
        require(msg.sender == operator, "Only operator");
        batchId++;
        batches[batchId] = Batch(root, block.timestamp, false);
        emit Submitted(batchId, root);
    }

    function challenge(uint256 id) external {
        Batch storage b = batches[id];
        require(block.timestamp < b.timestamp + challengeWindow, "Too late");
        require(!b.challenged, "Already challenged");
        b.challenged = true;
        emit Challenged(id);
    }
}
