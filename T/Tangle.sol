// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TangleModule - Simulates DAG-Based Ledger with Attack and Defense in Solidity

// ==============================
// 🔓 Vulnerable DAG-Like Ledger
// ==============================
contract TangleLedger {
    struct Node {
        address issuer;
        uint256 timestamp;
        uint256 weight;
        uint256[] parents;
        string data;
    }

    mapping(uint256 => Node) public nodes;
    uint256 public nodeCount;

    event NodeAdded(uint256 indexed id, address indexed issuer);

    function addNode(uint256[] calldata parents, string calldata data) external {
        nodes[nodeCount] = Node({
            issuer: msg.sender,
            timestamp: block.timestamp,
            weight: 1,
            parents: parents,
            data: data
        });

        emit NodeAdded(nodeCount, msg.sender);
        nodeCount++;
    }

    function getNode(uint256 id) external view returns (Node memory) {
        return nodes[id];
    }
}

// ==============================
// 🔓 Attack Contract - Tip Spammer / Self-Referencer
// ==============================
interface ITangleLedger {
    function addNode(uint256[] calldata, string calldata) external;
}

contract TangleAttack {
    ITangleLedger public target;

    constructor(address _target) {
        target = ITangleLedger(_target);
    }

    function spamTips(uint256 count) external {
        for (uint256 i = 0; i < count; i++) {
            uint256 ;
            parents[0] = i > 0 ? i - 1 : 0;
            target.addNode(parents, "SPAM");
        }
    }

    function selfRefNode() external {
        uint256 ;
        self[0] = 0;
        target.addNode(self, "SELF");
    }
}

// ==============================
// 🔐 Safe Tangle with Constraints
// ==============================
contract SafeTangleLedger {
    struct Node {
        address issuer;
        uint256 timestamp;
        uint256 weight;
        uint256[] parents;
        string data;
    }

    mapping(uint256 => Node) public nodes;
    mapping(uint256 => bool) public confirmed;
    uint256 public nodeCount;

    uint256 public constant MAX_DEPTH = 50;
    uint256 public constant MIN_APPROVALS = 2;

    event SafeNodeAdded(uint256 indexed id, address indexed issuer);

    function addSafeNode(uint256[] calldata parents, string calldata data) external {
        require(parents.length >= MIN_APPROVALS, "Need >= 2 parents");

        for (uint256 i = 0; i < parents.length; i++) {
            require(parents[i] < nodeCount, "Invalid parent");
            require(block.timestamp - nodes[parents[i]].timestamp < MAX_DEPTH, "Parent too old");
        }

        nodes[nodeCount] = Node({
            issuer: msg.sender,
            timestamp: block.timestamp,
            weight: 1,
            parents: parents,
            data: data
        });

        confirmed[nodeCount] = true;
        emit SafeNodeAdded(nodeCount, msg.sender);
        nodeCount++;
    }

    function isConfirmed(uint256 id) external view returns (bool) {
        return confirmed[id];
    }

    function getNode(uint256 id) external view returns (Node memory) {
        return nodes[id];
    }
}
