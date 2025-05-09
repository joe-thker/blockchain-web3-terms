// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SupercomputerSuite
/// @notice 1) JobScheduler, 2) ResultVerifier, 3) ReputationManager

///////////////////////////////////////////////////////////////////////////
// 1) Job Submission & Scheduling
///////////////////////////////////////////////////////////////////////////
contract JobScheduler {
    uint256 public constant MAX_JOBS_PER_USER = 10;
    uint256 public minStake = 0.1 ether;

    struct Job { address user; bytes payload; bool executed; }
    mapping(uint256 => Job) public jobs;
    mapping(address => uint256[]) public userJobs;
    uint256 public jobCount;
    mapping(address => uint256) public stakes;

    // --- Attack: anyone submits unlimited jobs with no stake
    function submitJobInsecure(bytes calldata payload) external {
        jobs[jobCount] = Job(msg.sender, payload, false);
        userJobs[msg.sender].push(jobCount);
        jobCount++;
    }

    // --- Defense: require stake + per‐user cap
    function stake() external payable {
        stakes[msg.sender] += msg.value;
    }
    function submitJobSecure(bytes calldata payload) external {
        require(stakes[msg.sender] >= minStake, "Insufficient stake");
        require(userJobs[msg.sender].length < MAX_JOBS_PER_USER, "Per-user cap");
        jobs[jobCount] = Job(msg.sender, payload, false);
        userJobs[msg.sender].push(jobCount);
        jobCount++;
    }
}

///////////////////////////////////////////////////////////////////////////
// 2) Result Verification
///////////////////////////////////////////////////////////////////////////
interface IProofVerifier {
    function verify(bytes calldata proof, bytes32 resultHash) external view returns (bool);
}

contract ResultVerifier is ReentrancyGuard {
    IProofVerifier public verifier;
    mapping(uint256 => bool) public jobExists;
    mapping(uint256 => bool) public executed;
    mapping(bytes32 => bool) public seenResults; // jobId|resultHash

    constructor(address _verifier) {
        verifier = IProofVerifier(_verifier);
    }

    // --- Attack: accept any result without proof or replay guard
    function submitResultInsecure(uint256 jobId, bytes32 resultHash, bytes calldata /*proof*/) external {
        require(jobExists[jobId], "Unknown job");
        executed[jobId] = true;
        // store or emit result
    }

    // --- Defense: require zk proof + nullifier
    function submitResultSecure(
        uint256 jobId,
        bytes32 resultHash,
        bytes calldata proof
    ) external nonReentrant {
        require(jobExists[jobId], "Unknown job");
        bytes32 nullifier = keccak256(abi.encodePacked(jobId, resultHash));
        require(!seenResults[nullifier], "Result replay");
        require(verifier.verify(proof, resultHash), "Invalid proof");
        seenResults[nullifier] = true;
        executed[jobId] = true;
    }
}

///////////////////////////////////////////////////////////////////////////
// 3) Node Reputation & Rewards
///////////////////////////////////////////////////////////////////////////
contract ReputationManager is ReentrancyGuard {
    struct NodeInfo { uint256 rep; bool slashed; }
    mapping(address => NodeInfo) public nodes;
    mapping(address => mapping(uint256 => bool)) public attestations; // node => epoch => attested
    uint256 public rewardPerEpoch = 1 ether;
    mapping(address => uint256) public earned;
    mapping(address => mapping(uint256 => bool)) public claimed; // node => epoch => claimed

    // --- Attack: node self-votes to inflate rep, insecure payout
    function rewardInsecure(uint256 epoch) external {
        // no attestation check, no claimed guard
        earned[msg.sender] += rewardPerEpoch;
    }
    function withdrawInsecure() external {
        payable(msg.sender).transfer(earned[msg.sender]);
    }

    // --- Defense: require peer attestations + per-epoch cap + CEI
    function attestNode(address node, uint256 epoch) external {
        require(msg.sender != node, "No self-attest");
        attestations[node][epoch] = true;
    }
    function rewardSecure(address node, uint256 epoch) external {
        require(attestations[node][epoch], "No attestation");
        require(!claimed[node][epoch], "Already claimed");
        // Effects
        claimed[node][epoch] = true;
        earned[node] += rewardPerEpoch;
    }
    function withdrawSecure() external nonReentrant {
        uint256 amt = earned[msg.sender];
        require(amt > 0, "Nothing to withdraw");
        earned[msg.sender] = 0;
        payable(msg.sender).transfer(amt);
    }

    // fund contract
    receive() external payable {}
}
