// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SafeDeposit - Protects from accidental or duplicate unconfirmed tx resubmits
contract SafeDeposit {
    mapping(address => bool) public hasDeposited;

    event Deposited(address indexed user, uint256 amount);

    function deposit() external payable {
        require(!hasDeposited[msg.sender], "Already deposited");
        require(msg.value > 0, "No ETH sent");

        hasDeposited[msg.sender] = true;
        emit Deposited(msg.sender, msg.value);
    }
}
