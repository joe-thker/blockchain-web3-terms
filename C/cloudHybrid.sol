// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title HybridCloud
/// @notice A simple contract simulating a hybrid cloud where only authorized addresses can store data.
contract HybridCloud {
    address public owner;
    string private message;

    mapping(address => bool) public authorized;

    event MessageStored(string newMessage);
    event AuthorizationGranted(address indexed addr);
    event AuthorizationRevoked(address indexed addr);

    constructor() {
        owner = msg.sender;
        // Owner is authorized by default.
        authorized[msg.sender] = true;
    }

    /// @notice Grants authorization to store data.
    /// @param addr The address to authorize.
    function grantAuthorization(address addr) external {
        require(msg.sender == owner, "Only owner can grant authorization");
        authorized[addr] = true;
        emit AuthorizationGranted(addr);
    }

    /// @notice Revokes authorization.
    /// @param addr The address to revoke.
    function revokeAuthorization(address addr) external {
        require(msg.sender == owner, "Only owner can revoke authorization");
        authorized[addr] = false;
        emit AuthorizationRevoked(addr);
    }

    /// @notice Stores a message. Only authorized addresses can call this.
    /// @param _message The message to store.
    function storeMessage(string calldata _message) external {
        require(authorized[msg.sender], "Not authorized to store message");
        message = _message;
        emit MessageStored(_message);
    }

    /// @notice Retrieves the stored message.
    /// @return The current message.
    function getMessage() external view returns (string memory) {
        return message;
    }
}
