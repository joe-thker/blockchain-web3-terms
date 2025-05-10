// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// ------------------------------------------------------------------------
/// 1) Content Registry
/// ------------------------------------------------------------------------
contract ContentRegistry {
    address public owner;
    uint256 public constant MAX_CONTENT = 10000;
    mapping(bytes32 => bool) public isRegistered;
    bytes32[] public contentList;

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    event ContentRegistered(bytes32 hash);
    event ContentLocked(bytes32 hash);

    constructor() { owner = msg.sender; }

    // --- Attack: anyone registers unlimited bogus hashes
    function registerInsecure(bytes32 hash) external {
        isRegistered[hash] = true;
        contentList.push(hash);
        emit ContentRegistered(hash);
    }

    // --- Defense: onlyOwner + cap + idempotent + immutable after lock
    mapping(bytes32 => bool) public locked;
    function registerSecure(bytes32 hash) external onlyOwner {
        require(contentList.length < MAX_CONTENT, "Registry full");
        require(!isRegistered[hash], "Already registered");
        isRegistered[hash] = true;
        contentList.push(hash);
        emit ContentRegistered(hash);
    }

    // --- Attack: anyone can overwrite or remove
    function removeInsecure(bytes32 hash) external {
        isRegistered[hash] = false;
    }

    // --- Defense: onlyOwner can remove, and lock prevents removals
    function lockContent(bytes32 hash) external onlyOwner {
        require(isRegistered[hash], "Not registered");
        locked[hash] = true;
        emit ContentLocked(hash);
    }
    function removeSecure(bytes32 hash) external onlyOwner {
        require(isRegistered[hash], "Not registered");
        require(!locked[hash], "Locked");
        isRegistered[hash] = false;
    }
}

/// ------------------------------------------------------------------------
/// 2) Retrieval Incentivization
/// ------------------------------------------------------------------------
interface IRetrievalProof {
    function verifyRetrieval(bytes32 requestId, address node, bytes calldata proof) external view returns (bool);
}

contract Retrieval in ContentRegistry, ReentrancyGuard {
    IRetrievalProof public prover;
    uint256 public rewardPerRequest;

    struct Request {
        address user;
        uint256 reward;
        bool    claimed;
    }
    mapping(bytes32 => Request) public requests;

    event RetrievalRequested(bytes32 indexed id, address indexed user, uint256 reward);
    event RewardClaimed(bytes32 indexed id, address indexed node, uint256 reward);

    constructor(address _prover, uint256 _reward) {
        prover = IRetrievalProof(_prover);
        rewardPerRequest = _reward;
    }

    // --- Attack: anyone replays the same claim repeatedly
    function requestInsecure(bytes32 id) external payable {
        // no payment check
        requests[id] = Request(msg.sender, rewardPerRequest, false);
        emit RetrievalRequested(id, msg.sender, rewardPerRequest);
    }
    function claimInsecure(bytes32 id, bytes calldata proof) external {
        Request storage r = requests[id];
        require(!r.claimed, "Already claimed");
        // no proof verification
        r.claimed = true;
        payable(msg.sender).transfer(r.reward);
        emit RewardClaimed(id, msg.sender, r.reward);
    }

    // --- Defense: require payment, proof verification, and replay guard
    function requestSecure(bytes32 id) external payable {
        require(msg.value == rewardPerRequest, "Wrong reward");
        requests[id] = Request(msg.sender, msg.value, false);
        emit RetrievalRequested(id, msg.sender, msg.value);
    }
    function claimSecure(bytes32 id, bytes calldata proof) external nonReentrant {
        Request storage r = requests[id];
        require(r.reward > 0, "Unknown request");
        require(!r.claimed, "Already claimed");
        // verify node did serve data
        require(prover.verifyRetrieval(id, msg.sender, proof), "Invalid proof");
        r.claimed = true;
        payable(msg.sender).transfer(r.reward);
        emit RewardClaimed(id, msg.sender, r.reward);
    }
}

/// ------------------------------------------------------------------------
/// 3) Proof‐of‐Storage Audit
/// ------------------------------------------------------------------------
interface IPoRVerifier {
    function verify(bytes32 dataHash, uint256 challengeId, bytes calldata proof) external view returns (bool);
}

contract StorageAudit is ReentrancyGuard {
    IPoRVerifier public verifier;
    mapping(address => mapping(uint256 => bool)) public seen; // node → challengeId

    event ProofSubmitted(address indexed node, uint256 challengeId);

    constructor(address _verifier) {
        verifier = IPoRVerifier(_verifier);
    }

    // --- Attack: accept any proof or replay old proofs
    function submitProofInsecure(bytes32 dataHash, uint256 challengeId, bytes calldata proof) external {
        // no verification, no replay guard
        emit ProofSubmitted(msg.sender, challengeId);
    }

    // --- Defense: verify PoR and prevent replay
    function submitProofSecure(
        bytes32 dataHash,
        uint256 challengeId,
        bytes calldata proof
    ) external nonReentrant {
        require(!seen[msg.sender][challengeId], "Proof replay");
        require(verifier.verify(dataHash, challengeId, proof), "Invalid proof");
        seen[msg.sender][challengeId] = true;
        emit ProofSubmitted(msg.sender, challengeId);
    }
}
