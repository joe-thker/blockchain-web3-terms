// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShamirSecretSharingSuite
/// @notice Implements Basic Threshold, Dynamic Update, and On-Chain DKG patterns
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Reentrancy guard for safety
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Basic Threshold Sharing
contract BasicThreshold is Base, ReentrancyGuard {
    uint public threshold;      // K
    uint public totalShares;    // N
    bytes public secretHash;    // hash of secret for verification

    mapping(uint => bytes) public shares;          // idx → share
    mapping(uint => bool)  public revealed;        // idx → revealed flag

    constructor(uint _K, uint _N, bytes calldata _secretHash) {
        require(_K > 0 && _K <= _N, "Invalid threshold");
        threshold   = _K;
        totalShares = _N;
        secretHash  = _secretHash;
    }

    // --- Attack: anyone can deal shares, no checks
    function dealSharesInsecure(bytes[] calldata _shares) external {
        require(_shares.length == totalShares, "Wrong N");
        for (uint i = 0; i < totalShares; i++) {
            shares[i] = _shares[i];
        }
    }

    // --- Defense: onlyOwner + verify each share against secretHash commitment
    function dealSharesSecure(bytes[] calldata _shares, bytes[] calldata proofs) external onlyOwner nonReentrant {
        require(_shares.length == totalShares && proofs.length == totalShares, "Invalid input");
        for (uint i = 0; i < totalShares; i++) {
            // verify proof: sha256(share ∥ i) == proofs[i]
            require(keccak256(abi.encodePacked(_shares[i], i)) == keccak256(proofs[i]), "Bad share proof");
            shares[i] = _shares[i];
            revealed[i] = false;
        }
    }

    // --- Attack: reveal without threshold or proof
    function recoverInsecure(uint[] calldata idxs) external view returns (bytes[] memory) {
        bytes[] memory out = new bytes[](idxs.length);
        for (uint i = 0; i < idxs.length; i++) {
            out[i] = shares[idxs[i]];
        }
        return out;
    }

    // --- Defense: enforce threshold and verify secret hash after reconstruction off-chain
    function recoverSecure(uint[] calldata idxs) external onlyOwner view returns (bytes[] memory) {
        require(idxs.length >= threshold, "Below threshold");
        bytes[] memory out = new bytes[](idxs.length);
        for (uint i = 0; i < idxs.length; i++) {
            require(shares[idxs[i]].length != 0, "Missing share");
            out[i] = shares[idxs[i]];
        }
        return out;
    }
}

/// 2) Dynamic Share Update
contract DynamicShareUpdate is Base {
    struct Share { bytes data; uint updatedAt; }
    mapping(address => Share) public shareBook;
    uint public minUpdateInterval = 1 hours;

    // --- Attack: anyone can overwrite any share, no timing
    function updateShareInsecure(address participant, bytes calldata newShare) external {
        shareBook[participant].data = newShare;
        shareBook[participant].updatedAt = block.timestamp;
    }

    // --- Defense: only participant + time spacing + commitment proof
    modifier onlyShareOwner(address participant) {
        require(msg.sender == participant, "Not share owner");
        _;
    }

    function updateShareSecure(bytes calldata newShare, bytes32 proof) external onlyShareOwner(msg.sender) {
        Share storage s = shareBook[msg.sender];
        require(block.timestamp >= s.updatedAt + minUpdateInterval, "Too soon");
        // proof: keccak256(newShare) must match provided proof
        require(keccak256(newShare) == proof, "Invalid proof");
        s.data = newShare;
        s.updatedAt = block.timestamp;
    }
}

/// 3) On-Chain DKG
contract OnChainDKG is Base {
    struct Participant {
        bool    joined;
        uint    stake;
        bytes32 commitment;   // hash of polynomial coefficients
    }
    mapping(address => Participant) public participants;
    address[] public participantList;
    uint public requiredStake;
    uint public maxParticipants;

    constructor(uint _stake, uint _max) {
        requiredStake     = _stake;
        maxParticipants   = _max;
    }

    // --- Attack: open registration, no stake, no limit
    function registerInsecure() external {
        participants[msg.sender] = Participant(true, 0, bytes32(0));
        participantList.push(msg.sender);
    }

    // --- Defense: require deposit, unique, and cap
    function registerSecure() external payable nonReentrant {
        require(!participants[msg.sender].joined, "Already in");
        require(participantList.length < maxParticipants, "Full");
        require(msg.value == requiredStake, "Bad stake");
        participants[msg.sender] = Participant(true, msg.value, bytes32(0));
        participantList.push(msg.sender);
    }

    // --- Attack: submit bad commitment
    function submitCommitmentInsecure(bytes32 com) external {
        participants[msg.sender].commitment = com;
    }

    // --- Defense: only joined + nonzero + on-chain format check
    function submitCommitmentSecure(bytes32 com) external {
        Participant storage p = participants[msg.sender];
        require(p.joined, "Not joined");
        require(com != bytes32(0), "Empty commitment");
        // simple format check: high bits nonzero (example)
        require(uint256(com) >> 248 != 0, "Bad format");
        p.commitment = com;
    }

    // Finalize: check that enough participants have committed
    function finalizeInsecure() external view returns (bool) {
        return true;   // no checks
    }

    function finalizeSecure() external view returns (bool) {
        uint count = 0;
        for (uint i = 0; i < participantList.length; i++) {
            if (participants[participantList[i]].commitment != bytes32(0)) {
                count++;
            }
        }
        // require at least a majority to proceed
        return count * 2 > participantList.length;
    }
}
