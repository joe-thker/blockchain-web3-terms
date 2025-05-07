// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
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
// 1) Hard-Coded Secrets
//////////////////////////////////////////////////////
contract SecretLeak is Base {
    // --- Attack: secret baked into source
    bytes32 private privateKey = 0xdeadbeefcafebabe1234567890abcdefdeadbeefcafebabe1234567890abcdef;

    function revealSecretInsecure() external view returns (bytes32) {
        return privateKey;
    }

    // --- Defense: inject secret via constructor, never stored in source
    bytes32 private secretKey;
    constructor(bytes32 _secretKey) {
        secretKey = _secretKey;
    }

    function revealSecretSecure() external view onlyOwner returns (bytes32) {
        return secretKey;
    }
}

//////////////////////////////////////////////////////
// 2) Unprotected selfdestruct
//////////////////////////////////////////////////////
contract Destructible is Base {
    // --- Attack: anyone can kill
    function killInsecure() external {
        selfdestruct(payable(msg.sender));
    }

    // --- Defense: onlyOwner + timelock before destruction
    uint256 public killRequestedAt;
    uint256 public constant DELAY = 1 days;

    function requestKill() external onlyOwner {
        killRequestedAt = block.timestamp;
    }
    function killSecure() external onlyOwner {
        require(killRequestedAt > 0 && block.timestamp >= killRequestedAt + DELAY, "Too early");
        selfdestruct(payable(owner));
    }
}

//////////////////////////////////////////////////////
// 3) Unverified External Code Imports
//////////////////////////////////////////////////////
contract LibUser is Base, ReentrancyGuard {
    address public libImpl;                // address of external logic
    bytes32 public expectedCodeHash;       // known good codehash

    event Upgraded(address newImpl);

    // --- Attack: no check before delegatecall
    function upgradeInsecure(address newImpl) external onlyOwner {
        libImpl = newImpl;
        emit Upgraded(newImpl);
    }
    fallback() external payable {
        // insecure delegate
        (bool ok, ) = libImpl.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }

    // --- Defense: verify extcodehash matches expected before upgrade
    function upgradeSecure(address newImpl, bytes32 codeHash) external onlyOwner {
        bytes32 actual;
        assembly { actual := extcodehash(newImpl) }
        require(actual == codeHash, "Codehash mismatch");
        libImpl = newImpl;
        expectedCodeHash = codeHash;
        emit Upgraded(newImpl);
    }

    fallback(bytes calldata) external payable {
        (bool ok, ) = libImpl.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }
}
