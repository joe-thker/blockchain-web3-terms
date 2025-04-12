// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FraudProofRollup {
    struct Commitment {
        bytes32 stateRoot;
        uint256 timestamp;
        address sequencer;
        bool challenged;
    }

    uint256 public fraudWindow = 1 days;
    uint256 public commitmentCount;
    mapping(uint256 => Commitment) public commitments;

    event StateCommitted(uint256 indexed id, address indexed sequencer, bytes32 root);
    event FraudChallenged(uint256 indexed id, address indexed challenger);
    event FraudProven(uint256 indexed id, address indexed challenger, string reason);

    modifier onlySequencer() {
        require(msg.sender == sequencer, "Only sequencer");
        _;
    }

    address public sequencer;

    constructor(address _sequencer) {
        sequencer = _sequencer;
    }

    function submitState(bytes32 stateRoot) external onlySequencer {
        commitments[commitmentCount] = Commitment({
            stateRoot: stateRoot,
            timestamp: block.timestamp,
            sequencer: msg.sender,
            challenged: false
        });

        emit StateCommitted(commitmentCount, msg.sender, stateRoot);
        commitmentCount++;
    }

    /// Example fraud detection: someone shows invalid transition hash
    function challengeFraud(uint256 id, bytes calldata fakeProof) external {
        Commitment storage c = commitments[id];
        require(block.timestamp <= c.timestamp + fraudWindow, "Fraud window closed");
        require(!c.challenged, "Already challenged");

        c.challenged = true;
        emit FraudChallenged(id, msg.sender);

        // ✅ Dummy fraud verification (replace with zk / merkle challenge logic)
        if (keccak256(fakeProof) != c.stateRoot) {
            emit FraudProven(id, msg.sender, "Invalid transition detected");
            // In real systems: slash sequencer, reward challenger
        }
    }

    function getCommitment(uint256 id) external view returns (bytes32 root, uint256 time, bool isChallenged) {
        Commitment memory c = commitments[id];
        return (c.stateRoot, c.timestamp, c.challenged);
    }

    /// Owner can update sequencer (upgrade path)
    function updateSequencer(address newSequencer) external {
        require(msg.sender == sequencer, "Only current sequencer");
        sequencer = newSequencer;
    }
}
