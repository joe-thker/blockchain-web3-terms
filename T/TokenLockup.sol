// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenLockupModule - Secure Token Lockup Mechanisms with Attack Simulation

// ==============================
// 🪙 Lockable ERC20 Token
// ==============================
contract LockableToken {
    string public name = "LockableToken";
    string public symbol = "LOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public lockUntil;

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function mint(address to, uint256 amt, uint256 lockDuration) external {
        require(msg.sender == admin, "Not admin");
        balances[to] += amt;
        totalSupply += amt;
        lockUntil[to] = block.timestamp + lockDuration;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(block.timestamp >= lockUntil[msg.sender], "Still locked");
        require(balances[msg.sender] >= amt, "Low balance");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(block.timestamp >= lockUntil[from], "Locked");
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
// 🔐 Token Lock Vault With Strict Unlock
// ==============================
abstract contract ReentrancyGuard {
    bool internal locked;
    modifier nonReentrant() {
        require(!locked, "Reentrant");
        locked = true;
        _;
        locked = false;
    }
}

contract TokenLockVault is ReentrancyGuard {
    LockableToken public token;
    mapping(address => uint256) public lockedBalance;
    mapping(address => uint256) public unlockTime;
    mapping(address => bool) public unlocked;

    constructor(address _token) {
        token = LockableToken(_token);
    }

    function deposit(uint256 amt, uint256 lockDuration) external {
        require(token.transferFrom(msg.sender, address(this), amt), "Transfer failed");
        lockedBalance[msg.sender] += amt;
        unlockTime[msg.sender] = block.timestamp + lockDuration;
        unlocked[msg.sender] = false;
    }

    function unlock() external nonReentrant {
        require(!unlocked[msg.sender], "Already unlocked");
        require(block.timestamp >= unlockTime[msg.sender], "Still locked");

        uint256 amt = lockedBalance[msg.sender];
        require(amt > 0, "Zero");
        lockedBalance[msg.sender] = 0;
        unlocked[msg.sender] = true;

        require(token.transfer(msg.sender, amt), "Transfer fail");
    }
}

// ==============================
// 🔓 Unsafe Lockup (Backdoor Bypass)
// ==============================
contract UnsafeLockup {
    LockableToken public token;
    mapping(address => uint256) public locked;
    mapping(address => uint256) public unlockAfter;
    address public admin;

    constructor(address _token) {
        token = LockableToken(_token);
        admin = msg.sender;
    }

    function lock(address user, uint256 amt, uint256 duration) external {
        require(msg.sender == admin, "Not admin");
        token.transferFrom(user, address(this), amt);
        locked[user] = amt;
        unlockAfter[user] = block.timestamp + duration;
    }

    function unlockBackdoor(address user) external {
        require(msg.sender == admin, "Backdoor only");
        token.transfer(user, locked[user]);
    }
}

// ==============================
// 🔓 Attacker: Calls Reentrancy or Early Claim
// ==============================
interface IVault {
    function unlock() external;
}

contract LockupAttacker {
    IVault public target;

    constructor(address _target) {
        target = IVault(_target);
    }

    function tryReenterUnlock() external {
        target.unlock();
        target.unlock(); // second call (should fail)
    }

    receive() external payable {}
}
