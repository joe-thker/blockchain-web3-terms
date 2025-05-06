// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SignalSuite
/// @notice Implements SimpleSignal, EventSignal, and RelaySignal patterns
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Basic reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Simple State Signal
contract SimpleSignal is Base {
    bool public flag;
    uint256 public version;

    // --- Attack: anyone flips the flag, no access control
    function flipInsecure() external {
        flag = !flag;
    }

    // --- Defense: onlyOwner + versioning + one-time flip
    function flipSecure() external onlyOwner {
        require(version == 0, "Already signaled");
        flag = true;
        version = 1;
    }
}

/// 2) Event-Only Signal
contract EventSignal is Base {
    // --- Attack: emit an event but no on-chain record
    event SignalInsecure(uint256 id);

    function signalInsecure(uint256 id) external {
        emit SignalInsecure(id);
    }

    // --- Defense: mirror in storage + nonce tracking
    event SignalSecure(uint256 id);
    mapping(uint256 => bool) public seen;

    function signalSecure(uint256 id) external onlyOwner {
        require(!seen[id], "Already signaled");
        seen[id] = true;
        emit SignalSecure(id);
    }
}

/// 3) Cross-Contract Signal Relay
contract RelayReceiver is Base, ReentrancyGuard {
    // record of relayed signals
    mapping(bytes32 => bool) public received;

    // --- Attack: anyone can call and spoof a signal
    function relayInsecure(bytes32 sigId) external {
        received[sigId] = true;
    }

    // --- Defense: only accept from trusted emitter + CEI
    address public trustedEmitter;
    function setEmitter(address emitter) external onlyOwner {
        trustedEmitter = emitter;
    }

    function relaySecure(bytes32 sigId) external nonReentrant {
        require(msg.sender == trustedEmitter, "Untrusted emitter");
        require(!received[sigId], "Already relayed");
        received[sigId] = true;
    }
}
