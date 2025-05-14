// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TrustlessModule - Demonstrates trustless vs non-trustless contract logic

/// ✅ Trustless Vault (no owner, no upgradability)
contract TrustlessVault {
    mapping(address => uint256) public balances;

    constructor() {}

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Too much");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}

/// ✅ Trustless Token (No minting, no pausing, no ownership)
contract TrustlessToken {
    string public name = "Trustless Token";
    string public symbol = "TRST";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);

    constructor(uint256 _supply) {
        balances[msg.sender] = _supply;
        totalSupply = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Low balance");
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
        require(balances[from] >= amount, "Low balance");
        require(allowance[from][msg.sender] >= amount, "Not approved");
        balances[from] -= amount;
        balances[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

/// 🧨 Fake Trustless Vault (Has hidden backdoor)
contract FakeTrustVault {
    mapping(address => uint256) public balances;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Too much");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // 🛑 Dangerous backdoor for the "trusted" owner
    function adminDrain(address payable to) external {
        require(msg.sender == owner, "Only owner");
        to.transfer(address(this).balance);
    }
}
