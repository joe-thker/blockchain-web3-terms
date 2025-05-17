// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface INodeVerifier {
    function isValidNode(address node) external view returns (bool);
}

contract VPNAccessManager {
    address public immutable admin;
    uint256 public constant SESSION_DURATION = 10 minutes;

    struct Subscription {
        uint256 expiry;
        address currentNode;
        uint256 sessionStartedAt;
    }

    mapping(address => Subscription) public subscriptions;
    mapping(address => bool) public exitNodes;

    event Subscribed(address indexed user, uint256 expiry);
    event NodeSessionStarted(address indexed user, address indexed node, uint256 startedAt);
    event NodeRegistered(address indexed node);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function subscribe(uint256 duration) external payable {
        require(duration >= 1 days, "Minimum 1 day");
        require(msg.value >= duration * 0.001 ether, "Insufficient fee");

        Subscription storage s = subscriptions[msg.sender];
        if (s.expiry < block.timestamp) {
            s.expiry = block.timestamp + duration;
        } else {
            s.expiry += duration;
        }

        emit Subscribed(msg.sender, s.expiry);
    }

    function registerExitNode(address node) external onlyAdmin {
        exitNodes[node] = true;
        emit NodeRegistered(node);
    }

    function startSession(address node) external {
        Subscription storage s = subscriptions[msg.sender];
        require(block.timestamp < s.expiry, "Subscription expired");
        require(exitNodes[node], "Invalid node");

        s.currentNode = node;
        s.sessionStartedAt = block.timestamp;

        emit NodeSessionStarted(msg.sender, node, block.timestamp);
    }

    function isSessionActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return s.currentNode != address(0) &&
               block.timestamp < s.sessionStartedAt + SESSION_DURATION &&
               block.timestamp < s.expiry;
    }

    function getRemainingTime(address user) external view returns (uint256) {
        if (block.timestamp >= subscriptions[user].expiry) return 0;
        return subscriptions[user].expiry - block.timestamp;
    }
}
