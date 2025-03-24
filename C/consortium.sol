// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Consortium
/// @notice A simple consortium governance system where only authorized members can perform consortium actions.
/// The owner can add or remove members.
contract Consortium {
    address public owner;
    mapping(address => bool) public members;
    address[] public memberList;

    event MemberAdded(address indexed newMember);
    event MemberRemoved(address indexed removedMember);
    event ConsortiumActionExecuted(address indexed member, string message);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only consortium members allowed");
        _;
    }

    /// @notice Constructor sets the deployer as the owner and first consortium member.
    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
        memberList.push(msg.sender);
        emit MemberAdded(msg.sender);
    }

    /// @notice Adds a new member to the consortium.
    /// @param _member The address to add as a member.
    function addMember(address _member) external onlyOwner {
        require(!members[_member], "Address is already a member");
        members[_member] = true;
        memberList.push(_member);
        emit MemberAdded(_member);
    }

    /// @notice Removes a member from the consortium.
    /// @param _member The address to remove.
    function removeMember(address _member) external onlyOwner {
        require(members[_member], "Address is not a member");
        members[_member] = false;
        // Remove the member from the memberList array.
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MemberRemoved(_member);
    }

    /// @notice Checks whether a given address is a member.
    /// @param _addr The address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _addr) external view returns (bool) {
        return members[_addr];
    }

    /// @notice Returns the list of consortium members.
    /// @return An array of addresses of the consortium members.
    function getMembers() external view returns (address[] memory) {
        return memberList;
    }

    /// @notice A sample function that simulates a consortium action.
    /// Only authorized members can execute this action.
    /// @return A string message confirming the action execution.
    function consortiumAction() external onlyMember returns (string memory) {
        emit ConsortiumActionExecuted(msg.sender, "Consortium action executed");
        return "Consortium action executed";
    }
}
