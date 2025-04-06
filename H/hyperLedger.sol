// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PermissionedLedger {
    address public admin;

    enum Role { None, Member, Admin }
    mapping(address => Role) public roles;

    struct Record {
        address user;
        string data;
        uint256 timestamp;
    }

    Record[] public ledger;

    modifier onlyAdmin() {
        require(roles[msg.sender] == Role.Admin, "Admin only");
        _;
    }

    modifier onlyMember() {
        require(roles[msg.sender] == Role.Member || roles[msg.sender] == Role.Admin, "Members only");
        _;
    }

    constructor() {
        admin = msg.sender;
        roles[admin] = Role.Admin;
    }

    function addMember(address user) external onlyAdmin {
        roles[user] = Role.Member;
    }

    function addRecord(string calldata data) external onlyMember {
        ledger.push(Record(msg.sender, data, block.timestamp));
    }

    function getRecord(uint256 index) external view returns (Record memory) {
        return ledger[index];
    }

    function totalRecords() external view returns (uint256) {
        return ledger.length;
    }
}
