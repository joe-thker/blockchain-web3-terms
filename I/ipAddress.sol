// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IPAddressRegistry
/// @notice Store and retrieve off-chain IP addresses for user sessions
contract IPAddressRegistry {
    mapping(address => string) public userIPs;
    event IPLogged(address indexed user, string ip);

    /// @notice Save the IP address (passed from frontend or oracle)
    function logIP(string calldata ip) external {
        userIPs[msg.sender] = ip;
        emit IPLogged(msg.sender, ip);
    }

    /// @notice Get a user's last known IP
    function getUserIP(address user) external view returns (string memory) {
        return userIPs[user];
    }
}
