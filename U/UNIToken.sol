// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MiniUniToken - Minimal ERC20 clone with delegation logic
contract MiniUniToken {
    string public name = "UNI Token";
    string public symbol = "UNI";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => address) public delegates;
    mapping(address => uint256) public votingPower;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event DelegateChanged(address indexed delegator, address indexed delegatee);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        balances[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient");
        _moveVotingPower(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balances[from] >= amount, "Insufficient");
        require(allowance[from][msg.sender] >= amount, "Not allowed");

        allowance[from][msg.sender] -= amount;
        _moveVotingPower(from, to, amount);
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function delegate(address to) external {
        address prev = delegates[msg.sender];
        uint256 balance = balances[msg.sender];

        if (prev != address(0)) {
            votingPower[prev] -= balance;
        }

        delegates[msg.sender] = to;
        votingPower[to] += balance;

        emit DelegateChanged(msg.sender, to);
    }

    function votePowerOf(address user) external view returns (uint256) {
        return votingPower[user];
    }

    function _moveVotingPower(address from, address to, uint256 amount) internal {
        address fromDelegate = delegates[from];
        address toDelegate = delegates[to];

        if (fromDelegate != address(0)) {
            votingPower[fromDelegate] -= amount;
        }
        if (toDelegate != address(0)) {
            votingPower[toDelegate] += amount;
        }
    }
}
