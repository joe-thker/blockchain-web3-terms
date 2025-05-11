// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenIssuanceModule - Secure Token Minting, Rate Control, and Exploit Simulation

// ==============================
// 🪙 Issuable Token (Cap + Minter)
// ==============================
contract IssuableToken {
    string public name = "IssuableToken";
    string public symbol = "ISSUE";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public immutable cap;
    address public minter;

    mapping(address => uint256) public balances;

    constructor(uint256 _cap) {
        cap = _cap;
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    function mint(address to, uint256 amt) external onlyMinter {
        require(totalSupply + amt <= cap, "Cap exceeded");
        balances[to] += amt;
        totalSupply += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Low balance");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    function setMinter(address _minter) external onlyMinter {
        minter = _minter;
    }
}

// ==============================
// 🔓 Token Issuer (Vulnerable - No Rate Control)
// ==============================
interface IToken {
    function mint(address, uint256) external;
}

contract TokenIssuer {
    IToken public token;

    constructor(address _token) {
        token = IToken(_token);
    }

    function issueTo(address user, uint256 amt) external {
        token.mint(user, amt);
    }
}

// ==============================
// 🔓 Attacker (Mint Overflow + Reentrancy)
// ==============================
interface IMintable {
    function mint(address, uint256) external;
}

contract IssuanceAttacker {
    IMintable public target;
    bool public entered;

    constructor(address _target) {
        target = IMintable(_target);
    }

    function attack(address victim, uint256 amt) external {
        require(!entered, "Already in");
        entered = true;
        target.mint(victim, amt); // try to mint unbounded or reenter
        entered = false;
    }
}

// ==============================
// 🔐 Safe Issuer (Rate-Limited + Cap + Guarded)
// ==============================
abstract contract ReentrancyGuard {
    bool internal locked;
    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
}

contract SafeTokenIssuer is ReentrancyGuard {
    IssuableToken public token;
    uint256 public lastIssued;
    uint256 public issuanceRate = 100 ether; // max per day
    uint256 public constant INTERVAL = 1 days;

    constructor(address _token) {
        token = IssuableToken(_token);
    }

    function issue(address to) external nonReentrant {
        require(block.timestamp >= lastIssued + INTERVAL, "Wait for interval");
        lastIssued = block.timestamp;
        token.mint(to, issuanceRate);
    }
}
