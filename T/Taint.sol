// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TaintModule - Simulates Taint Propagation and Protection in Web3 Systems

// ==============================
// 🧪 Taint Registry (Denylist)
// ==============================
contract TaintRegistry {
    mapping(address => bool) public isTainted;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function markTainted(address target) external {
        require(msg.sender == admin, "Only admin");
        isTainted[target] = true;
    }

    function unmark(address target) external {
        require(msg.sender == admin, "Only admin");
        isTainted[target] = false;
    }
}

// ==============================
// 🔓 Tainted ERC20-Like Token
// ==============================
contract TaintedToken {
    string public name = "TaintedToken";
    string public symbol = "TAINT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    TaintRegistry public registry;

    event Transfer(address indexed from, address indexed to, uint256 value, bool tainted);

    constructor(uint256 _supply, address registryAddress) {
        balances[msg.sender] = _supply;
        totalSupply = _supply;
        registry = TaintRegistry(registryAddress);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "Low balance");
        balances[msg.sender] -= value;
        balances[to] += value;

        bool tainted = registry.isTainted(msg.sender);
        emit Transfer(msg.sender, to, value, tainted);

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balances[from] >= value, "Low balance");
        require(allowance[from][msg.sender] >= value, "Not approved");
        balances[from] -= value;
        balances[to] += value;
        allowance[from][msg.sender] -= value;

        bool tainted = registry.isTainted(from);
        emit Transfer(from, to, value, tainted);

        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🔐 Safe Receiver With Taint Block
// ==============================
interface ITaintRegistry {
    function isTainted(address) external view returns (bool);
}

contract SafeReceiver {
    ITaintRegistry public registry;
    address public owner;

    constructor(address _registry) {
        registry = ITaintRegistry(_registry);
        owner = msg.sender;
    }

    receive() external payable {
        require(!registry.isTainted(msg.sender), "Tainted sender");
    }

    function receiveToken(address token, uint256 amount) external {
        require(!registry.isTainted(msg.sender), "Blocked tainted sender");
        (bool ok,) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount));
        require(ok, "Transfer failed");
    }
}

// ==============================
// 🔄 Taint Forwarder Bot (Relays Taint)
// ==============================
contract TaintForwarder {
    address public taintSink;

    constructor(address _sink) {
        taintSink = _sink;
    }

    receive() external payable {
        payable(taintSink).transfer(address(this).balance);
    }

    function forwardToken(address token, uint256 amount) external {
        (bool ok,) = token.call(abi.encodeWithSignature("transfer(address,uint256)", taintSink, amount));
        require(ok, "Relay failed");
    }
}
