// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFutoDAO {
    function isMember(address addr) external view returns (bool);
}

contract FutoTreasury {
    address public dao;
    constructor(address daoAddress) {
        dao = daoAddress;
    }

    receive() external payable {}

    modifier onlyDAO() {
        require(IFutoDAO(dao).isMember(msg.sender), "Not DAO member");
        _;
    }

    function withdraw(address payable to, uint256 amount) external onlyDAO {
        require(address(this).balance >= amount, "Insufficient funds");
        to.transfer(amount);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}
