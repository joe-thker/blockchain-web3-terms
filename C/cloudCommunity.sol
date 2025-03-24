// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CommunityCloud
/// @notice A simple contract simulating a community cloud where only consortium members can store data.
/// Membership is managed by the owner.
contract CommunityCloud {
    address public owner;
    string private message;

    mapping(address => bool) public members;
    address[] public memberList;

    event MessageStored(string newMessage);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);

    constructor() {
        owner = msg.sender;
        // Owner is a member by default.
        members[msg.sender] = true;
        memberList.push(msg.sender);
        emit MemberAdded(msg.sender);
    }

    /// @notice Adds a new member to the community cloud.
    /// @param member The address to add.
    function addMember(address member) external {
        require(msg.sender == owner, "Only owner can add members");
        require(!members[member], "Already a member");
        members[member] = true;
        memberList.push(member);
        emit MemberAdded(member);
    }

    /// @notice Removes a member from the community cloud.
    /// @param member The address to remove.
    function removeMember(address member) external {
        require(msg.sender == owner, "Only owner can remove members");
        require(members[member], "Not a member");
        members[member] = false;
        // Remove from memberList (for simplicity, not optimized)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MemberRemoved(member);
    }

    /// @notice Stores a message. Only community members can call this.
    /// @param _message The message to store.
    function storeMessage(string calldata _message) external {
        require(members[msg.sender], "Not a community member");
        message = _message;
        emit MessageStored(_message);
    }

    /// @notice Retrieves the stored message.
    /// @return The current message.
    function getMessage() external view returns (string memory) {
        return message;
    }

    /// @notice Retrieves the list of community members.
    /// @return An array of addresses representing the members.
    function getMembers() external view returns (address[] memory) {
        return memberList;
    }
}
