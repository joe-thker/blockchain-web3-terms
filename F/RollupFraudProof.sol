// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RollupFraudProof {
    struct StateCommitment {
        bytes32 stateRoot;
        uint256 timestamp;
        bool challenged;
    }

    mapping(uint256 => StateCommitment) public commitments;
    uint256 public commitmentIndex;
    address public sequencer;
    uint256 public fraudWindow = 1 days;

    event Committed(uint256 indexed id, bytes32 root);
    event Challenged(uint256 indexed id, address challenger);

    constructor(address _sequencer) {
        sequencer = _sequencer;
    }

    function commit(bytes32 root) external {
        require(msg.sender == sequencer, "Only sequencer");
        commitments[commitmentIndex] = StateCommitment(root, block.timestamp, false);
        emit Committed(commitmentIndex, root);
        commitmentIndex++;
    }

    function challenge(uint256 id, bytes calldata fakeProof) external {
        StateCommitment storage c = commitments[id];
        require(!c.challenged, "Already challenged");
        require(block.timestamp <= c.timestamp + fraudWindow, "Fraud window passed");

        c.challenged = true;
        emit Challenged(id, msg.sender);

        if (keccak256(fakeProof) != c.stateRoot) {
            // Slash sequencer, reward challenger
        }
    }
}
