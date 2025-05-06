// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SoftForkSuite
/// @notice Demonstrates LegacyDeprecation, RuleEnforcement, and VersionedCalls patterns
abstract contract Base {
    uint256 public forkBlock;     // block when soft fork activates
    bool    public forkActivated;
    uint256 public version;       // contract version

    constructor(uint256 _version) {
        version = _version;
    }

    modifier onlyPostFork() {
        require(forkActivated, "Fork not active");
        _;
    }

    // Owner can activate fork at or after a certain block
    function activateFork(uint256 atBlock) external {
        require(!forkActivated, "Already activated");
        require(block.number >= atBlock,    "Too early");
        forkBlock = atBlock;
        forkActivated = true;
    }
}

/// Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

//////////////////////////////////////////////////////
// 1) Legacy Function Deprecation
//////////////////////////////////////////////////////
contract LegacyDeprecation is Base {
    mapping(address => uint256) public balances;

    constructor() Base(1) {}

    // --- Attack: legacy withdraw always available
    function legacyWithdrawInsecure(uint256 amount) external {
        // even after fork, this still works
        require(balances[msg.sender] >= amount, "Insufficient");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // --- Defense: disable legacy path once forkActivated
    function legacyWithdrawSecure(uint256 amount) external onlyPostFork {
        require(balances[msg.sender] >= amount, "Insufficient");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // deposit to balance
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    receive() external payable { deposit(); }
}

//////////////////////////////////////////////////////
// 2) New Rule Enforcement
//////////////////////////////////////////////////////
contract RuleEnforcement is Base {
    bool public ruleEnabled;
    mapping(address => uint256) public data;

    constructor() Base(1) {}

    // --- Attack: accept any value even if it violates new rule
    function setDataInsecure(uint256 x) external {
        data[msg.sender] = x;
    }

    // --- Defense: enforce new rule (e.g., must be even) once forkActivated
    function setDataSecure(uint256 x) external {
        if (forkActivated) {
            // new rule: only even values allowed
            require(x % 2 == 0, "Value must be even");
        }
        data[msg.sender] = x;
    }

    // enable rule flag if needed
    function enableRule() external onlyPostFork {
        ruleEnabled = true;
    }
}

//////////////////////////////////////////////////////
// 3) Version Signaling & Compatibility
//////////////////////////////////////////////////////
contract VersionedCalls is Base, ReentrancyGuard {
    mapping(bytes32 => bool) public seenCall;

    constructor(uint256 initialVersion) Base(initialVersion) {}

    // --- Attack: call without version check, replay across versions
    function callInsecure(address target, bytes calldata payload) external {
        // no version or replay protection
        (bool ok, ) = target.call(payload);
        require(ok, "Call failed");
    }

    // --- Defense: include version & check compatibility + replay nonce
    function callSecure(
        address target,
        bytes calldata payload,
        uint256 targetVersion,
        uint256 nonce
    ) external nonReentrant {
        // ensure this call hasn't been used
        bytes32 id = keccak256(abi.encodePacked(msg.sender, target, payload, nonce, targetVersion));
        require(!seenCall[id], "Replay");
        seenCall[id] = true;

        // query target's version() if available
        (bool ok, bytes memory ret) = target.staticcall(abi.encodeWithSignature("version()"));
        require(ok && abi.decode(ret, (uint256)) == targetVersion, "Incompatible version");

        // proceed with the actual call
        (ok,) = target.call(payload);
        require(ok, "Call failed");
    }
}
