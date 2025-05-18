// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WhitelistAccess {
    address public immutable owner;
    mapping(address => bool) public directWhitelist;
    bytes32 public merkleRoot;

    event Added(address indexed user);
    event RootUpdated(bytes32 indexed newRoot);

    constructor(bytes32 _root) {
        owner = msg.sender;
        merkleRoot = _root;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice Add direct whitelist entry (manual control)
    function addToWhitelist(address user) external onlyOwner {
        directWhitelist[user] = true;
        emit Added(user);
    }

    /// @notice Update Merkle root for tree-based whitelist
    function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
        emit RootUpdated(newRoot);
    }

    /// @notice Check if user is whitelisted via either method
    function isWhitelisted(address user, bytes32[] calldata proof) public view returns (bool) {
        if (directWhitelist[user]) return true;
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /// @notice Example function restricted to whitelisted users
    function restrictedAction(bytes32[] calldata proof) external {
        require(isWhitelisted(msg.sender, proof), "Not whitelisted");
        // perform restricted action
    }
}
