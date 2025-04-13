// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FutoDAO {
    address public chair;
    mapping(address => bool) public members;

    event MemberAdded(address member);
    event MemberRemoved(address member);

    modifier onlyChair() {
        require(msg.sender == chair, "Not chair");
        _;
    }

    constructor() {
        chair = msg.sender;
        members[msg.sender] = true;
    }

    function addMember(address addr) external onlyChair {
        members[addr] = true;
        emit MemberAdded(addr);
    }

    function removeMember(address addr) external onlyChair {
        members[addr] = false;
        emit MemberRemoved(addr);
    }

    function isMember(address addr) external view returns (bool) {
        return members[addr];
    }
}
