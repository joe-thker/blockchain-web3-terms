// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FUDsterDAO {
    mapping(address => bool) public voters;
    mapping(address => uint256) public strikes;
    uint256 public constant STRIKE_LIMIT = 3;

    event Voted(address voter, address target, uint256 totalStrikes);

    constructor(address[] memory members) {
        for (uint256 i = 0; i < members.length; i++) {
            voters[members[i]] = true;
        }
    }

    function voteToBan(address target) external {
        require(voters[msg.sender], "Not a DAO member");
        strikes[target]++;
        emit Voted(msg.sender, target, strikes[target]);
    }

    function isBanned(address user) external view returns (bool) {
        return strikes[user] >= STRIKE_LIMIT;
    }
}
