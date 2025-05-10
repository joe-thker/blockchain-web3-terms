// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TendermintModule - Tendermint-Inspired BFT Consensus Simulation with Attack and Defense

// ==============================
// 📘 Validator Registry
// ==============================
contract ValidatorRegistry {
    mapping(address => bool) public isValidator;
    mapping(address => uint256) public penalties;
    address[] public validatorList;

    constructor(address[] memory validators) {
        for (uint256 i = 0; i < validators.length; i++) {
            isValidator[validators[i]] = true;
            validatorList.push(validators[i]);
        }
    }

    function slash(address validator) external {
        require(isValidator[validator], "Not validator");
        penalties[validator] += 1 ether;
    }

    function isQuorum(uint256 votes) public view returns (bool) {
        return votes * 3 >= validatorList.length * 2; // >⅔
    }

    function getValidators() external view returns (address[] memory) {
        return validatorList;
    }
}

// ==============================
// 🔓 Insecure Tendermint-Style Consensus
// ==============================
contract TendermintConsensus {
    struct Proposal {
        address proposer;
        string data;
        uint256 round;
        uint256 timestamp;
    }

    struct Vote {
        address voter;
        bytes32 proposalHash;
    }

    ValidatorRegistry public registry;
    Proposal public currentProposal;
    Vote[] public votes;
    bytes32 public committedHash;

    event Proposed(address proposer, string data, uint256 round);
    event Voted(address voter, bytes32 hash);
    event Committed(bytes32 hash);

    constructor(address _registry) {
        registry = ValidatorRegistry(_registry);
    }

    function propose(string memory data, uint256 round) external {
        require(registry.isValidator(msg.sender), "Not validator");
        currentProposal = Proposal(msg.sender, data, round, block.timestamp);
        delete votes;
        emit Proposed(msg.sender, data, round);
    }

    function vote(bytes32 proposalHash) external {
        require(registry.isValidator(msg.sender), "Not validator");
        votes.push(Vote(msg.sender, proposalHash));
        emit Voted(msg.sender, proposalHash);
    }

    function commit() external {
        require(votes.length > 0, "No votes");
        committedHash = votes[0].proposalHash;
        emit Committed(committedHash);
    }
}

// ==============================
// 🔓 Byzantine Vote Injection Attacker
// ==============================
interface IVoteable {
    function vote(bytes32) external;
}

contract ByzantineAttacker {
    function doubleVote(address consensus, bytes32 hashA, bytes32 hashB) external {
        IVoteable(consensus).vote(hashA);
        IVoteable(consensus).vote(hashB); // Double vote = equivocation
    }
}

// ==============================
// 🔐 Hardened Tendermint Consensus with Slashing
// ==============================
contract SafeTendermintConsensus {
    struct Proposal {
        address proposer;
        string data;
        uint256 round;
        uint256 timestamp;
    }

    struct Vote {
        bool exists;
        bytes32 proposalHash;
    }

    ValidatorRegistry public registry;
    Proposal public currentProposal;
    mapping(address => Vote) public voteMap;
    uint256 public voteCount;
    bytes32 public committedHash;

    event Proposed(address proposer, string data, uint256 round);
    event Voted(address voter, bytes32 hash);
    event Slashed(address indexed voter);
    event Committed(bytes32 hash);

    constructor(address _registry) {
        registry = ValidatorRegistry(_registry);
    }

    function propose(string memory data, uint256 round) external {
        require(registry.isValidator(msg.sender), "Not validator");
        currentProposal = Proposal(msg.sender, data, round, block.timestamp);
        voteCount = 0;

        for (uint256 i = 0; i < registry.getValidators().length; i++) {
            delete voteMap[registry.getValidators()[i]];
        }

        emit Proposed(msg.sender, data, round);
    }

    function vote(bytes32 proposalHash) external {
        require(registry.isValidator(msg.sender), "Not validator");
        if (voteMap[msg.sender].exists) {
            // Double-vote detected
            if (voteMap[msg.sender].proposalHash != proposalHash) {
                registry.slash(msg.sender);
                emit Slashed(msg.sender);
            }
        } else {
            voteMap[msg.sender] = Vote(true, proposalHash);
            voteCount++;
            emit Voted(msg.sender, proposalHash);
        }
    }

    function commit() external {
        require(registry.isQuorum(voteCount), "No quorum");
        committedHash = keccak256(abi.encodePacked(currentProposal.data));
        emit Committed(committedHash);
    }
}
