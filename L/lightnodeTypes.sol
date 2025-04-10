// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Light Node Types
/// @notice Simulates different light node interaction patterns in Solidity

/// 1. Header-Only Verification Node
contract HeaderVerifier {
    struct BlockHeader {
        bytes32 parentHash;
        bytes32 stateRoot;
        uint256 timestamp;
    }

    mapping(uint256 => BlockHeader) public headers;

    function submitHeader(uint256 blockNumber, bytes32 parentHash, bytes32 stateRoot) external {
        headers[blockNumber] = BlockHeader(parentHash, stateRoot, block.timestamp);
    }

    function getHeader(uint256 blockNumber) external view returns (BlockHeader memory) {
        return headers[blockNumber];
    }
}

/// 2. Proof-Carrying Data Light Node
contract ProofValidator {
    event ProofValidated(address user, bytes32 txHash);

    function validateProof(bytes calldata proof, bytes32 expectedHash) external {
        // Simulate checking Merkle proof, skip actual validation
        require(keccak256(proof) == expectedHash, "Invalid proof");
        emit ProofValidated(msg.sender, expectedHash);
    }
}

/// 3. Oracle-Fed Light Node Data
contract OracleLightNode {
    mapping(uint256 => bytes32) public verifiedBlocks;
    address public oracle;

    modifier onlyOracle() {
        require(msg.sender == oracle, "Not oracle");
        _;
    }

    constructor(address _oracle) {
        oracle = _oracle;
    }

    function submitVerifiedBlock(uint256 blockNumber, bytes32 blockHash) external onlyOracle {
        verifiedBlocks[blockNumber] = blockHash;
    }

    function isBlockVerified(uint256 blockNumber, bytes32 claimedHash) external view returns (bool) {
        return verifiedBlocks[blockNumber] == claimedHash;
    }
}

/// 4. Event-Synced Light Node (Simulated L2)
contract EventSyncedNode {
    event SyncedFromL2(uint256 blockNumber, bytes32 root);
    mapping(uint256 => bytes32) public l2Roots;

    function syncL2(uint256 blockNumber, bytes32 root) external {
        l2Roots[blockNumber] = root;
        emit SyncedFromL2(blockNumber, root);
    }

    function verifyL2Root(uint256 blockNumber, bytes32 root) external view returns (bool) {
        return l2Roots[blockNumber] == root;
    }
}
