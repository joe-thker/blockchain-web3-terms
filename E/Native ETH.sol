// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NativeEtherVault {
    mapping(address => uint256) public balances;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    function deposit() public payable {
        require(msg.value > 0, "Send ETH");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough ETH");
        balances[msg.sender] -= amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to withdraw");
        emit Withdrawn(msg.sender, amount);
    }

    receive() external payable {
        deposit();
    }
}
