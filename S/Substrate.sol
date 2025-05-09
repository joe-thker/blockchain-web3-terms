// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// ------------------------------------------------------------------------
/// 1) Runtime Upgrade
/// ------------------------------------------------------------------------
contract RuntimeUpgrade {
    address public owner;
    address public implementation;
    uint256 public version;
    bytes32 public expectedCodehash;

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    constructor(address impl, bytes32 codehash) {
        owner              = msg.sender;
        implementation     = impl;
        expectedCodehash   = codehash;
        version            = 1;
    }

    // --- Insecure: anyone can upgrade to any implementation
    function upgradeInsecure(address newImpl) external {
        implementation = newImpl;
    }

    // --- Secure: onlyOwner + monotonic version + codehash verify
    function upgradeSecure(address newImpl, bytes32 newHash) external onlyOwner {
        require(newHash == expectedCodehash, "Checksum mismatch");
        version++;
        implementation   = newImpl;
        expectedCodehash = newHash;
    }
}

/// ------------------------------------------------------------------------
/// 2) Pallet Call Execution
/// ------------------------------------------------------------------------
contract PalletDispatcher is ReentrancyGuard {
    address public owner;
    mapping(address=>bytes32) public palletCodehash;  // allowed pallet ⇒ codehash

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    constructor() { owner = msg.sender; }

    // register or remove pallets
    function setPallet(address pallet, bytes32 codehash) external onlyOwner {
        if (codehash == bytes32(0)) {
            delete palletCodehash[pallet];
        } else {
            palletCodehash[pallet] = codehash;
        }
    }

    // --- Insecure: delegatecall to any pallet
    function dispatchInsecure(address pallet, bytes calldata data) external {
        (bool ok, ) = pallet.delegatecall(data);
        require(ok, "dispatch failed");
    }

    // --- Secure: only whitelisted pallets + codehash check + nonReentrant
    function dispatchSecure(address pallet, bytes calldata data) external nonReentrant {
        bytes32 expected = palletCodehash[pallet];
        require(expected != bytes32(0), "Pallet not allowed");
        bytes32 actual;
        assembly { actual := extcodehash(pallet) }
        require(actual == expected, "Codehash mismatch");

        (bool ok, ) = pallet.delegatecall(data);
        require(ok, "dispatch failed");
    }
}

/// ------------------------------------------------------------------------
/// 3) Cross-Chain Message (XCMP)
/// ------------------------------------------------------------------------
contract XcmpRelay is ReentrancyGuard {
    address public owner;
    mapping(address=>bool) public relayers;
    mapping(uint256 => mapping(uint256 => bool)) public seen; // srcChainId → nonce → seen

    event Relayed(uint256 srcChain, uint256 dstChain, uint256 nonce, bytes payload);

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    modifier onlyRelayer() { require(relayers[msg.sender], "Not relayer"); _; }

    constructor() { owner = msg.sender; }

    function setRelayer(address who, bool ok) external onlyOwner {
        relayers[who] = ok;
    }

    // --- Insecure: relay any message, allow replay & spoof
    function relayInsecure(
        uint256 srcChain,
        uint256 dstChain,
        uint256 nonce,
        bytes calldata payload
    ) external {
        emit Relayed(srcChain, dstChain, nonce, payload);
    }

    // --- Secure: relayer only, prevent replay, require source signature
    function relaySecure(
        uint256 srcChain,
        uint256 dstChain,
        uint256 nonce,
        bytes calldata payload,
        bytes calldata srcSignature
    ) external onlyRelayer nonReentrant {
        require(!seen[srcChain][nonce], "Replay");
        // verify signature from source chain authority (owner for demo)
        bytes32 h = keccak256(abi.encodePacked(srcChain, dstChain, nonce, payload));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(srcSignature, (bytes32,bytes32,uint8));
        address signer = ecrecover(msgHash, v, r, s);
        require(signer == owner, "Bad sig");

        seen[srcChain][nonce] = true;
        emit Relayed(srcChain, dstChain, nonce, payload);
    }
}
