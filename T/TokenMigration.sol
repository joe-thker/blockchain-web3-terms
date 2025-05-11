// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenMigrationModule - Secure Token Migration with Attack Simulation

// ==============================
// 🪙 Old ERC20 Token (Legacy)
// ==============================
contract OldToken {
    string public name = "OldToken";
    string public symbol = "OLD";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        totalSupply = 1_000_000 ether;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
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
// 🆕 New ERC20 Token (Post-Migration)
// ==============================
contract NewToken {
    string public name = "NewToken";
    string public symbol = "NEW";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public minter;
    mapping(address => uint256) public balances;

    constructor() {
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    function mint(address to, uint256 amt) external onlyMinter {
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
}

// ==============================
// 🔐 Secure Migration Vault
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

interface IOldToken {
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

interface INewToken {
    function mint(address, uint256) external;
}

contract MigrationVault is ReentrancyGuard {
    IOldToken public oldToken;
    INewToken public newToken;
    mapping(address => bool) public migrated;

    event Migrated(address indexed user, uint256 amount);

    constructor(address _old, address _new) {
        oldToken = IOldToken(_old);
        newToken = INewToken(_new);
    }

    function migrate() external nonReentrant {
        require(!migrated[msg.sender], "Already migrated");

        uint256 amt = oldToken.balanceOf(msg.sender);
        require(amt > 0, "Nothing to migrate");
        require(oldToken.transferFrom(msg.sender, address(this), amt), "Transfer failed");

        migrated[msg.sender] = true;
        newToken.mint(msg.sender, amt);
        emit Migrated(msg.sender, amt);
    }
}

// ==============================
// 🔓 Attacker - Double Migrate or On-Behalf Attempt
// ==============================
interface IMigration {
    function migrate() external;
}

contract MigrationAttacker {
    IMigration public target;

    constructor(address _target) {
        target = IMigration(_target);
    }

    function doubleMigrate() external {
        target.migrate();
        target.migrate(); // try again
    }
}
