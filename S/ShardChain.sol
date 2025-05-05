// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShardChainSuite
/// @notice ValidatorRegistry, StateRootSubmission, and CrosslinkManager for shard chains
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Reentrancy guard
abstract contract ReentrancyGuard {
    bool private _lock;
    modifier nonReentrant() {
        require(!_lock, "Reentrant");
        _lock = true;
        _;
        _lock = false;
    }
}

/// 1) Validator Registry
contract ValidatorRegistry is Base, ReentrancyGuard {
    struct Validator { uint256 stake; uint256 exitTime; bool active; }
    mapping(address => Validator) public validators;
    uint256 public minStake = 32 ether;
    uint256 public unbondingPeriod = 7 days;

    // --- Attack: anyone registers without stake and can exit immediately
    function registerInsecure() external {
        validators[msg.sender] = Validator(0, 0, true);
    }

    // --- Defense: enforce min stake and record stake
    function registerSecure() external payable nonReentrant {
        require(!validators[msg.sender].active, "Already validator");
        require(msg.value >= minStake, "Insufficient stake");
        validators[msg.sender] = Validator(msg.value, 0, true);
    }

    // --- Attack: exit without delay & withdraw any amount
    function exitInsecure() external {
        Validator storage v = validators[msg.sender];
        require(v.active, "Not validator");
        payable(msg.sender).transfer(address(this).balance);
        delete validators[msg.sender];
    }

    // --- Defense: set exitTime, enforce delay, then withdraw stake
    function exitSecure() external nonReentrant {
        Validator storage v = validators[msg.sender];
        require(v.active, "Not validator");
        require(v.exitTime == 0, "Already exiting");
        v.exitTime = block.timestamp + unbondingPeriod;
    }
    function withdrawSecure() external nonReentrant {
        Validator storage v = validators[msg.sender];
        require(v.active && v.exitTime != 0, "Not exiting");
        require(block.timestamp >= v.exitTime, "Unbonding");
        uint256 amt = v.stake;
        v.active = false;
        v.stake = 0;
        payable(msg.sender).transfer(amt);
    }

    // allow contract to receive stake refunds
    receive() external payable {}
}

/// 2) State Root Submission
contract StateRootSubmission is Base {
    uint256 public lastEpoch;
    mapping(uint256 => bytes32) public epochRoot;
    uint256 public submissionWindow = 1 hours;
    mapping(uint256 => uint256) public epochTime;

    // --- Attack: anyone posts any root at any epoch
    function postRootInsecure(uint256 epoch, bytes32 root) external {
        epochRoot[epoch] = root;
    }

    // --- Defense: onlyOwner + monotonic epoch + time‐window
    function postRootSecure(uint256 epoch, bytes32 root) external onlyOwner {
        require(epoch == lastEpoch + 1, "Wrong epoch");
        require(block.timestamp >= epochTime[lastEpoch] + submissionWindow, "Too early");
        epochRoot[epoch] = root;
        epochTime[epoch] = block.timestamp;
        lastEpoch = epoch;
    }
}

/// 3) Crosslink Manager
contract CrosslinkManager is Base, ReentrancyGuard {
    bytes32 public beaconRoot;
    mapping(bytes32 => bool) public processed;

    event CrosslinkFinalized(uint256 shardId, uint256 epoch, bytes32 root, bytes32 msgId);

    // --- Attack: anyone updates beaconRoot
    function finalizeInsecure(uint256 shardId, uint256 epoch, bytes32 root, bytes32 msgId) external {
        beaconRoot = root;
        emit CrosslinkFinalized(shardId, epoch, root, msgId);
    }

    // --- Defense: require proof + no replay + CEI
    function finalizeSecure(
        uint256 shardId,
        uint256 epoch,
        bytes32 root,
        bytes32 msgId,
        bytes32[] calldata proof
    ) external nonReentrant onlyOwner {
        require(!processed[msgId], "Already processed");
        // verify Merkle proof: leaf = keccak256(shardId ∥ epoch ∥ root)
        bytes32 leaf = keccak256(abi.encodePacked(shardId, epoch, root));
        require(_verifyProof(leaf, proof, beaconRoot), "Invalid proof");
        processed[msgId] = true;
        // Effects
        beaconRoot = root;
        emit CrosslinkFinalized(shardId, epoch, root, msgId);
    }

    // simple sorted‐pair Merkle proof
    function _verifyProof(
        bytes32 leaf,
        bytes32[] memory proof,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 hash = leaf;
        for (uint i = 0; i < proof.length; i++) {
            bytes32 p = proof[i];
            if (hash < p) {
                hash = keccak256(abi.encodePacked(hash, p));
            } else {
                hash = keccak256(abi.encodePacked(p, hash));
            }
        }
        return hash == root;
    }
}
