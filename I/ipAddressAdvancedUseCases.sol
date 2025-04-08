// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Advanced IP Address Use Cases in Solidity

/// 1. Proof-of-Location (PoL) IP Logging
contract ProofOfLocation {
    struct LocationLog {
        string ip;
        string geoHash;
        uint256 timestamp;
    }

    mapping(address => LocationLog[]) public userLocations;

    event LocationSubmitted(address indexed user, string ip, string geoHash);

    function submitLocation(string calldata ip, string calldata geoHash) external {
        userLocations[msg.sender].push(LocationLog(ip, geoHash, block.timestamp));
        emit LocationSubmitted(msg.sender, ip, geoHash);
    }

    function getLatestLocation(address user) external view returns (LocationLog memory) {
        uint256 len = userLocations[user].length;
        require(len > 0, "No location data");
        return userLocations[user][len - 1];
    }
}

/// 2. Oracle Push Node Health/IP Data
contract NodeOracleLogger {
    struct NodeStatus {
        string ip;
        bool active;
        uint256 lastPing;
    }

    mapping(address => NodeStatus) public nodeHealth;
    address public oracle;

    modifier onlyOracle() {
        require(msg.sender == oracle, "Not oracle");
        _;
    }

    constructor(address _oracle) {
        oracle = _oracle;
    }

    event NodeUpdated(address node, string ip, bool active);

    function updateNode(address node, string calldata ip, bool active) external onlyOracle {
        nodeHealth[node] = NodeStatus(ip, active, block.timestamp);
        emit NodeUpdated(node, ip, active);
    }
}

/// 3. IP Whitelist by Region
contract RegionalWhitelist {
    mapping(string => bool) public approvedRegions;
    mapping(address => string) public userRegions;

    event Whitelisted(address user, string region);

    function approveRegion(string calldata region) external {
        approvedRegions[region] = true;
    }

    function registerRegion(string calldata region) external {
        require(approvedRegions[region], "Region not allowed");
        userRegions[msg.sender] = region;
        emit Whitelisted(msg.sender, region);
    }

    function isWhitelisted(address user) external view returns (bool) {
        return approvedRegions[userRegions[user]];
    }
}

/// 4. Node Reputation Tracker (IP + Uptime)
contract NodeReputationTracker {
    struct Reputation {
        string ip;
        uint256 totalUptime;
        uint256 lastCheckIn;
    }

    mapping(address => Reputation) public reputations;

    event NodeCheckedIn(address indexed node, string ip);

    function checkIn(string calldata ip) external {
        Reputation storage rep = reputations[msg.sender];
        if (rep.lastCheckIn != 0) {
            rep.totalUptime += block.timestamp - rep.lastCheckIn;
        }
        rep.lastCheckIn = block.timestamp;
        rep.ip = ip;
        emit NodeCheckedIn(msg.sender, ip);
    }

    function getUptime(address node) external view returns (uint256) {
        return reputations[node].totalUptime;
    }
}
