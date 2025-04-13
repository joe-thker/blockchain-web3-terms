// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFutoDAOGrants {
    function isMember(address) external view returns (bool);
}

contract FutoGrants {
    address public dao;
    mapping(address => uint256) public grants;

    event GrantIssued(address indexed recipient, uint256 amount);

    modifier onlyDAO() {
        require(IFutoDAOGrants(dao).isMember(msg.sender), "Not authorized");
        _;
    }

    constructor(address daoAddr) {
        dao = daoAddr;
    }

    function issueGrant(address recipient, uint256 amount) external onlyDAO {
        grants[recipient] += amount;
        emit GrantIssued(recipient, amount);
    }

    function getGrant(address recipient) external view returns (uint256) {
        return grants[recipient];
    }
}
