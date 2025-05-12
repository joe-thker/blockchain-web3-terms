// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenomicsModule - Tokenomics Engine with Mint, Burn, Fee, Vesting and Governance

// ==============================
// 🪙 Tokenomics Token (ERC20 + Mint + Burn + Fee)
// ==============================
contract TokenomicsToken {
    string public name = "EconoToken";
    string public symbol = "ECON";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public immutable cap;
    address public admin;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public feePercent = 1; // 1% burn fee on transfer

    constructor(uint256 _cap) {
        admin = msg.sender;
        cap = _cap;
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

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balances[msg.sender] >= amt, "Low balance");
        uint256 fee = (amt * feePercent) / 100;
        balances[msg.sender] -= amt;
        balances[to] += (amt - fee);
        totalSupply -= fee; // burn
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(balances[from] >= amt && allowance[from][msg.sender] >= amt, "Denied");
        uint256 fee = (amt * feePercent) / 100;
        balances[from] -= amt;
        balances[to] += (amt - fee);
        allowance[from][msg.sender] -= amt;
        totalSupply -= fee;
        return true;
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
// ⏳ Vesting Vault
// ==============================
contract VestingVault {
    TokenomicsToken public token;
    uint256 public unlockTime;
    mapping(address => uint256) public allocations;
    mapping(address => bool) public claimed;

    constructor(address _token, uint256 _delay) {
        token = TokenomicsToken(_token);
        unlockTime = block.timestamp + _delay;
    }

    function allocate(address user, uint256 amt) external {
        require(msg.sender == token.admin(), "Not admin");
        allocations[user] += amt;
    }

    function claim() external {
        require(block.timestamp >= unlockTime, "Locked");
        require(!claimed[msg.sender], "Already claimed");
        claimed[msg.sender] = true;
        token.mint(msg.sender, allocations[msg.sender]);
    }
}

// ==============================
// 🗳️ Governance Tracker (Snapshot Balance)
// ==============================
contract GovernanceTracker {
    TokenomicsToken public token;
    mapping(uint256 => mapping(address => uint256)) public snapshot;

    constructor(address _token) {
        token = TokenomicsToken(_token);
    }

    function record(uint256 proposalId) external {
        snapshot[proposalId][msg.sender] = token.balanceOf(msg.sender);
    }

    function voteWeight(address user, uint256 proposalId) external view returns (uint256) {
        return snapshot[proposalId][user];
    }
}

// ==============================
// 🔓 Tokenomics Attacker
// ==============================
interface IEconoToken {
    function mint(address, uint256) external;
    function transferFrom(address, address, uint256) external returns (bool);
}

contract TokenomicsAttacker {
    function tryOverMint(IEconoToken token, address to, uint256 amt) external {
        token.mint(to, amt); // should fail if not admin
    }

    function bypassFees(IEconoToken token, address from, address to, uint256 amt) external {
        token.transferFrom(from, to, amt); // test if fees are applied
    }
}
