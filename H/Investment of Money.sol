// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InvestmentToken {
    mapping(address => uint256) public balances;

    receive() external payable {
        require(msg.value > 0, "No investment");
        balances[msg.sender] += msg.value;
    }
}
