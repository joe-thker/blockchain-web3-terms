// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenizedSecuritiesModule - Security Token with Compliance and Registry

// ==============================
// 🛡️ Compliance Registry
// ==============================
contract ComplianceRegistry {
    mapping(address => bool) public isWhitelisted;
    mapping(address => string) public jurisdiction;

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function whitelist(address investor, string memory region) external {
        require(msg.sender == admin, "Only admin");
        isWhitelisted[investor] = true;
        jurisdiction[investor] = region;
    }

    function revoke(address investor) external {
        require(msg.sender == admin, "Only admin");
        isWhitelisted[investor] = false;
    }
}

// ==============================
// 🪙 Equity Security Token (ERC20 + Cap + Compliance)
// ==============================
contract EquityToken {
    string public name = "SecurityEquity";
    string public symbol = "EQUITY";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public immutable cap;

    ComplianceRegistry public registry;
    address public issuer;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address _registry, uint256 _cap) {
        registry = ComplianceRegistry(_registry);
        issuer = msg.sender;
        cap = _cap;
    }

    modifier onlyIssuer() {
        require(msg.sender == issuer, "Not issuer");
        _;
    }

    function mint(address to, uint256 amt) external onlyIssuer {
        require(totalSupply + amt <= cap, "Cap exceeded");
        require(registry.isWhitelisted(to), "Not whitelisted");
        balances[to] += amt;
        totalSupply += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(registry.isWhitelisted(to), "Target not whitelisted");
        require(balances[msg.sender] >= amt, "Insufficient");
        balances[msg.sender] -= amt;
        balances[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(registry.isWhitelisted(to), "Target not whitelisted");
        require(balances[from] >= amt && allowance[from][msg.sender] >= amt, "Denied");
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
// 🏛️ Secure Equity Issuer
// ==============================
contract SecureEquityIssuer {
    EquityToken public token;

    constructor(address _token) {
        token = EquityToken(_token);
    }

    function issue(address to, uint256 amt) external {
        token.mint(to, amt);
    }
}

// ==============================
// 🔓 Fake Investor (Bypass Attempt)
// ==============================
interface ISecurityToken {
    function transfer(address, uint256) external returns (bool);
}

contract FakeInvestor {
    function tryTransfer(ISecurityToken token, address to, uint256 amt) external {
        token.transfer(to, amt); // should fail if not whitelisted
    }
}
