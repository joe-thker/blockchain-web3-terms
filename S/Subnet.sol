// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

////////////////////////////////////////////////////////////////////////////////
// 1) Subnet Registry
////////////////////////////////////////////////////////////////////////////////
contract SubnetRegistry {
    address public owner;
    uint256 public constant MAX_SUBNETS = 100;

    mapping(uint256 => bool) public isRegistered;
    uint256[] public subnets;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // --- Attack: anyone can register unlimited bogus subnets
    function registerInsecure(uint256 subnetId) external {
        isRegistered[subnetId] = true;
        subnets.push(subnetId);
    }

    // --- Defense: onlyOwner + cap + idempotent
    function registerSecure(uint256 subnetId) external onlyOwner {
        require(subnets.length < MAX_SUBNETS, "Max subnets reached");
        require(!isRegistered[subnetId], "Already registered");
        isRegistered[subnetId] = true;
        subnets.push(subnetId);
    }

    // --- Attack: anyone can deregister, leaving stale holes
    function deregisterInsecure(uint256 subnetId) external {
        isRegistered[subnetId] = false;
    }

    // --- Defense: onlyOwner can deregister existing subnets
    function deregisterSecure(uint256 subnetId) external onlyOwner {
        require(isRegistered[subnetId], "Not registered");
        isRegistered[subnetId] = false;
        // note: removal from `subnets` array can be done off-chain
    }
}

////////////////////////////////////////////////////////////////////////////////
// 2) Transaction Routing
////////////////////////////////////////////////////////////////////////////////
contract TransactionRouter {
    mapping(address => mapping(uint256 => uint256)) public nonces; // user → subnetId → nonce
    SubnetRegistry public registry;

    constructor(address registryAddr) {
        registry = SubnetRegistry(registryAddr);
    }

    event Routed(address indexed user, uint256 subnetId, uint256 amount, uint256 nonce);

    // --- Attack: route to any subnet, no replay guard
    function routeInsecure(uint256 subnetId) external payable {
        require(msg.value > 0, "No funds");
        // no registry check, no nonce → funds may go to wrong subnet or be replayed
        emit Routed(msg.sender, subnetId, msg.value, 0);
    }

    // --- Defense: require registered subnet + per‐user nonce + CEI
    function routeSecure(uint256 subnetId) external payable {
        require(msg.value > 0, "No funds");
        require(registry.isRegistered(subnetId), "Subnet not registered");
        uint256 n = ++nonces[msg.sender][subnetId];
        // CEI complete, now emit for relayer consumption
        emit Routed(msg.sender, subnetId, msg.value, n);
    }
}

////////////////////////////////////////////////////////////////////////////////
// 3) Cross-Subnet Messaging
////////////////////////////////////////////////////////////////////////////////
contract CrossSubnetMessenger is ReentrancyGuard {
    address public owner;
    mapping(address => bool) public isRelayer;
    mapping(uint256 => mapping(uint256 => bool)) public seen; // subnetId → msgNonce → seen

    event MessageRelayed(uint256 srcSubnet, uint256 dstSubnet, uint256 nonce, bytes payload);

    modifier onlyRelayer() {
        require(isRelayer[msg.sender], "Not relayer");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setRelayer(address relayer, bool ok) external {
        require(msg.sender == owner, "Not owner");
        isRelayer[relayer] = ok;
    }

    // --- Attack: relayer can replay old messages or spoof from any subnet
    function relayInsecure(
        uint256 srcSubnet,
        uint256 dstSubnet,
        uint256 nonce,
        bytes calldata payload
    ) external {
        // no seen check, no relayer whitelist
        emit MessageRelayed(srcSubnet, dstSubnet, nonce, payload);
    }

    // --- Defense: whitelist relayer + prevent replay + require src signature
    function relaySecure(
        uint256 srcSubnet,
        uint256 dstSubnet,
        uint256 nonce,
        bytes calldata payload,
        bytes calldata srcSignature
    ) external onlyRelayer nonReentrant {
        require(!seen[srcSubnet][nonce], "Message replay");
        // verify signature from srcSubnet owner (off-chain known address)
        bytes32 h = keccak256(abi.encodePacked(srcSubnet, dstSubnet, nonce, payload));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        // in practice retrieve srcOwner from a registry; here assume owner for demo
        address signer = ecrecover(msgHash, uint8(srcSignature[64]), bytes32(srcSignature[:32]), bytes32(srcSignature[32:64]));
        require(signer == owner, "Invalid src sig");

        seen[srcSubnet][nonce] = true;
        emit MessageRelayed(srcSubnet, dstSubnet, nonce, payload);
    }
}

interface SubnetRegistry {
    function isRegistered(uint256) external view returns (bool);
}
