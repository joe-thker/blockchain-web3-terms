// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Valhalla Access Manager - Secure elite role system
contract ValhallaAccess {
    address public immutable deployer;
    bytes32 public constant VALHALLA_ROLE = keccak256("VALHALLA_ROLE");
    bool public initialized;

    mapping(address => bool) private _valhalla;
    mapping(bytes32 => bool) public zkProofRegistry;

    event EnterValhalla(address indexed user);
    event ExitValhalla(address indexed user);
    event ValhallaAccessed(address indexed caller, uint256 blockNumber, bytes4 selector);

    modifier onlyValhalla() {
        require(_valhalla[msg.sender], "Not Valhalla");
        _;
        emit ValhallaAccessed(msg.sender, block.number, msg.sig);
    }

    constructor() {
        deployer = msg.sender;
        _valhalla[msg.sender] = true;
    }

    /// @notice One-time initializer to prevent constructor bypass
    function initialize(address[] calldata elite) external {
        require(!initialized, "Already initialized");
        require(msg.sender == deployer, "Not deployer");
        for (uint i = 0; i < elite.length; i++) {
            _valhalla[elite[i]] = true;
        }
        initialized = true;
    }

    /// @notice ZK proof gate to grant Valhalla access
    function proveValhalla(bytes32 zkHashProof) external {
        require(zkProofRegistry[zkHashProof], "Invalid ZK proof");
        _valhalla[msg.sender] = true;
        emit EnterValhalla(msg.sender);
    }

    function revokeValhalla(address user) external onlyValhalla {
        require(user != msg.sender, "Self-revoke forbidden");
        _valhalla[user] = false;
        emit ExitValhalla(user);
    }

    function isValhalla(address user) external view returns (bool) {
        return _valhalla[user];
    }

    /// Simulated Valhalla action
    function summonOdin() external onlyValhalla returns (string memory) {
        return "Welcome to Valhalla, warrior!";
    }

    /// zkProof registry loader (can be onchain/offchain zk verified)
    function registerZKProof(bytes32 proofHash) external onlyValhalla {
        zkProofRegistry[proofHash] = true;
    }
}
