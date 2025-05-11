// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenModule - Attack and Defense of Token-Based Mechanics in Solidity

// ==============================
// 🔓 Fake ERC20 Token (Malicious)
// ==============================
contract FakeToken {
    string public name = "USD Coin";
    string public symbol = "USDC";
    uint8 public decimals = 6;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amt) external {
        balances[to] += amt;
        totalSupply += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Bad balance");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(balances[from] >= amt && allowance[from][msg.sender] >= amt, "Not allowed");
        balances[from] -= amt;
        balances[to] += amt;
        allowance[from][msg.sender] -= amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🔓 Token Attacker (Race & Abuse)
// ==============================
interface IERC20Abuse {
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract TokenAttacker {
    IERC20Abuse public target;

    constructor(address _target) {
        target = IERC20Abuse(_target);
    }

    function raceExploit(address victim, uint256 amt) external {
        target.transferFrom(victim, msg.sender, amt);
    }
}

// ==============================
// 🔐 Safe Token (ERC20 Cap + OpenZeppelin Pattern)
// ==============================
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract SafeERC20 is Context {
    string public name = "SafeToken";
    string public symbol = "SAFE";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public immutable cap;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _cap) {
        cap = _cap;
    }

    function mint(address to, uint256 amt) external {
        require(totalSupply + amt <= cap, "Cap exceeded");
        balances[to] += amt;
        totalSupply += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[_msgSender()] >= amt, "Insufficient");
        balances[_msgSender()] -= amt;
        balances[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[_msgSender()][spender] = amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(balances[from] >= amt && allowance[from][msg.sender] >= amt, "Not approved");
        balances[from] -= amt;
        balances[to] += amt;
        allowance[from][msg.sender] -= amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🧱 Token Validator: Symbol ↔ Address Verifier
// ==============================
contract TokenValidator {
    mapping(string => address) public knownTokens;

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function register(string calldata symbol, address token) external {
        require(msg.sender == admin, "Admin only");
        knownTokens[symbol] = token;
    }

    function verify(string calldata symbol, address token) external view returns (bool) {
        return knownTokens[symbol] == token;
    }
}
