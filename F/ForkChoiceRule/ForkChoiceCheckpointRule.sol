// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ForkChoiceCheckpointRule {
    struct Checkpoint {
        bytes32 forkId;
        uint256 epoch;
        bool justified;
    }

    mapping(bytes32 => Checkpoint) public checkpoints;
    bytes32 public latestJustified;

    event CheckpointSubmitted(bytes32 indexed forkId, uint256 epoch);
    event Justified(bytes32 indexed forkId);

    function submitCheckpoint(bytes32 forkId, uint256 epoch) external {
        checkpoints[forkId] = Checkpoint(forkId, epoch, false);
        emit CheckpointSubmitted(forkId, epoch);
    }

    function justify(bytes32 forkId) external {
        checkpoints[forkId].justified = true;

        if (
            checkpoints[forkId].epoch >
            checkpoints[latestJustified].epoch
        ) {
            latestJustified = forkId;
            emit Justified(forkId);
        }
    }

    function getLatestJustified() external view returns (bytes32) {
        return latestJustified;
    }
}
