// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TotalSupplyModule - Tracks and Enforces Token Supply Logic

// ==============================
// 🔒 Fixed Supply Token (Capped Mintable)
// ==============================
contract FixedSupplyToken {
    string public name = "FixedToken";
    string public symbol = "FXT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public immutable cap;
    address public admin;

    mapping(address => uint256) public balances;

    constructor(uint256 _cap) {
        cap = _cap;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function mint(address to, uint256 amt) external onlyAdmin {
        require(totalSupply + amt <= cap, "Cap exceeded");
        balances[to] += amt;
        totalSupply += amt;
    }

    function burn(uint256 amt) external {
        require(balances[msg.sender] >= amt, "Too much");
        balances[msg.sender] -= amt;
        totalSupply -= amt;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🌱 Inflationary Token (Auto Emission per Epoch)
// ==============================
contract InflationaryToken {
    string public name = "InflateCoin";
    string public symbol = "INF";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public admin;
    uint256 public lastEpoch;
    uint256 public emissionRate = 100 ether; // per day

    mapping(address => uint256) public balances;

    constructor() {
        admin = msg.sender;
        lastEpoch = block.timestamp;
    }

    function emitTokens() external {
        require(block.timestamp >= lastEpoch + 1 days, "Wait epoch");
        balances[admin] += emissionRate;
        totalSupply += emissionRate;
        lastEpoch = block.timestamp;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🔥 Burnable Token (Deflationary)
// ==============================
contract BurnableToken {
    string public name = "DeflaToken";
    string public symbol = "DFT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;

    constructor() {
        balances[msg.sender] = 1_000_000 ether;
        totalSupply = balances[msg.sender];
    }

    function burn(uint256 amt) external {
        require(balances[msg.sender] >= amt, "Low");
        balances[msg.sender] -= amt;
        totalSupply -= amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Insufficient");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}

// ==============================
// 🔓 Supply Attacker (Phantom Mint + Burn Bypass)
// ==============================
interface IFixedToken {
    function mint(address, uint256) external;
    function burn(uint256) external;
}

contract SupplyAttacker {
    function phantomMint(IFixedToken token, address to, uint256 amt) external {
        token.mint(to, amt); // should fail if cap enforced
    }

    function burnWithoutTotalChange(IFixedToken token, uint256 amt) external {
        token.burn(amt); // test if totalSupply adjusts properly
    }
}
