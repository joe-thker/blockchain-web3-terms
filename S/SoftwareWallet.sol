// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SoftwareWalletSuite
/// @notice Implements SimpleWallet, MultiSigWallet, and SocialRecoveryWallet
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor(address _owner) { owner = _owner; }
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
// 1) Simple Exec Wallet
//////////////////////////////////////////////////////
contract SimpleWallet is Base, ReentrancyGuard {
    uint256 public nonce;

    constructor(address _owner) Base(_owner) {}

    // --- Attack: anyone can call exec
    function execInsecure(address to, uint256 value, bytes calldata data) external {
        (bool ok, ) = to.call{value: value}(data);
        require(ok, "call failed");
    }

    // --- Defense: onlyOwner + include nonce in payload to prevent replay
    function execSecure(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 _nonce
    ) external onlyOwner nonReentrant {
        require(_nonce == nonce, "Bad nonce");
        nonce++;
        (bool ok, ) = to.call{value: value}(data);
        require(ok, "call failed");
    }

    receive() external payable {}
}

//////////////////////////////////////////////////////
// 2) Multisig Wallet
//////////////////////////////////////////////////////
contract MultiSigWallet is ReentrancyGuard {
    uint256 public nonce;
    address[] public owners;
    mapping(address=>bool) public isOwner;
    uint256 public threshold;

    event Executed(bytes32 txHash, address to, uint256 value, bytes data);

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_threshold>0 && _threshold<=_owners.length, "Bad threshold");
        owners = _owners;
        threshold = _threshold;
        for(uint i; i<_owners.length; i++){
            isOwner[_owners[i]] = true;
        }
    }

    // --- Attack: anyone can call exec without sigs
    function execInsecure(address to, uint256 value, bytes calldata data) external {
        (bool ok, ) = to.call{value: value}(data);
        require(ok, "call failed");
    }

    // --- Defense: require M-of-N ECDSA sigs + nonce + replay protection
    function execSecure(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 _nonce,
        bytes[] calldata sigs
    ) external nonReentrant {
        require(_nonce == nonce, "Bad nonce");
        bytes32 hash = keccak256(abi.encodePacked(address(this), to, value, data, _nonce));
        uint256 valid;
        address last;
        for(uint i; i<sigs.length; i++){
            (bytes32 r, bytes32 s, uint8 v) = abi.decode(sigs[i], (bytes32,bytes32,uint8));
            address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hash)), v, r, s);
            require(signer > last, "Duplicate or unordered");
            require(isOwner[signer], "Not owner");
            valid++;
            last = signer;
        }
        require(valid >= threshold, "Not enough sigs");
        nonce++;
        (bool ok, ) = to.call{value: value}(data);
        require(ok, "call failed");
        emit Executed(hash, to, value, data);
    }

    receive() external payable {}
}

//////////////////////////////////////////////////////
// 3) Social Recovery Wallet
//////////////////////////////////////////////////////
contract SocialRecoveryWallet is Base, ReentrancyGuard {
    address[] public guardians;
    uint256 public recoveryDelay;       // e.g. 1 day
    address public pendingOwner;
    uint256 public requestTime;

    event RecoveryRequested(address proposedOwner, uint256 at);
    event RecoveryFinalized(address newOwner);

    constructor(address _owner, address[] memory _guardians, uint256 _delay) Base(_owner) {
        guardians = _guardians;
        recoveryDelay = _delay;
    }

    // --- Attack: any guardian can immediately change owner
    function recoverInsecure(address newOwner) external {
        // no checks or delays
        owner = newOwner;
    }

    // --- Defense: only guardian can request, then delay, then accept
    function requestRecovery(address newOwner) external {
        bool ok;
        for(uint i; i<guardians.length; i++){
            if(msg.sender == guardians[i]) { ok = true; break; }
        }
        require(ok, "Not guardian");
        pendingOwner = newOwner;
        requestTime = block.timestamp;
        emit RecoveryRequested(newOwner, requestTime);
    }

    function finalizeRecovery() external nonReentrant {
        require(pendingOwner != address(0), "No pending");
        require(block.timestamp >= requestTime + recoveryDelay, "Delay not met");
        owner = pendingOwner;
        pendingOwner = address(0);
        emit RecoveryFinalized(owner);
    }
}
