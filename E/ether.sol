// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EtherVault {
    mapping(address => uint256) private balances;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    // Deposit Ether into the contract
    function deposit() public payable {
        require(msg.value > 0, "Send ETH to deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Withdraw Ether from the contract
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // View balance of sender
    function myBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    // Receive function handles plain ETH transfers
    receive() external payable {
        deposit();
    }

    // Fallback function handles non-matching calls with ETH
    fallback() external payable {
        deposit();
    }
}
