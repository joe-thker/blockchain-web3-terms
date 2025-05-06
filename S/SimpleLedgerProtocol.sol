// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SLPSuite
/// @notice Implements TokenIssuance, TokenTransfer, and OperatorControl modules
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// ERC20‐like interface for SLP
interface ISLP {
    function balanceOf(address) external view returns (uint256);
}

/// 1) Token Issuance & Minting
contract SLPTokenIssuance is Base, ReentrancyGuard {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    uint256 public cap;

    constructor(uint256 _cap) {
        cap = _cap;
    }

    // --- Attack: anyone mints unlimited tokens
    function mintInsecure(address to, uint256 amt) external {
        balanceOf[to] += amt;
        totalSupply += amt;
    }

    // --- Defense: onlyOwner + cap + CEI + reentrancy guard
    function mintSecure(address to, uint256 amt) external onlyOwner nonReentrant {
        require(totalSupply + amt <= cap, "Cap exceeded");
        // Effects
        totalSupply += amt;
        balanceOf[to] += amt;
    }

    // --- Attack: burn via depleting sender with no checks
    function burnInsecure(uint256 amt) external {
        balanceOf[msg.sender] -= amt;
        totalSupply -= amt;
    }

    // --- Defense: safe burn
    function burnSecure(uint256 amt) external nonReentrant {
        uint256 bal = balanceOf[msg.sender];
        require(bal >= amt, "Insufficient");
        balanceOf[msg.sender] = bal - amt;
        totalSupply -= amt;
    }
}

/// 2) Token Transfer & Approval
contract SLPTokenTransfer is Base {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Attack: transfer to zero address (accidental burn)
    function transferInsecure(address to, uint256 amt) external {
        balanceOf[msg.sender] -= amt;
        balanceOf[to] += amt;
    }

    // --- Defense: reject zero address and CEI
    function transferSecure(address to, uint256 amt) external returns (bool) {
        require(to != address(0), "Zero address");
        uint256 bal = balanceOf[msg.sender];
        require(bal >= amt, "Insufficient");
        // Effects
        balanceOf[msg.sender] = bal - amt;
        balanceOf[to] += amt;
        return true;
    }

    // --- Attack: naive approve vulnerable to frontrun
    function approveInsecure(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }

    // --- Defense: increase/decrease allowance
    function increaseAllowance(address spender, uint256 added) external returns (bool) {
        allowance[msg.sender][spender] += added;
        return true;
    }
    function decreaseAllowance(address spender, uint256 sub) external returns (bool) {
        uint256 old = allowance[msg.sender][spender];
        require(old >= sub, "Underflow");
        allowance[msg.sender][spender] = old - sub;
        return true;
    }

    // transferFrom variants similar
}

/// 3) Operator Management & Token Metadata
contract SLPOperatorControl is Base {
    mapping(address => bool) public isOperator;
    string public name;
    string public symbol;
    uint8  public decimals;

    event OperatorSet(address indexed op, bool allowed);
    event MetadataUpdated(string name, string symbol);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // --- Attack: anyone sets operator
    function setOperatorInsecure(address op, bool ok) external {
        isOperator[op] = ok;
        emit OperatorSet(op, ok);
    }

    // --- Defense: onlyOwner sets operator
    function setOperatorSecure(address op, bool ok) external onlyOwner {
        isOperator[op] = ok;
        emit OperatorSet(op, ok);
    }

    // --- Attack: metadata tampering anytime
    function updateMetadataInsecure(string calldata n, string calldata s) external {
        name = n; symbol = s;
        emit MetadataUpdated(n, s);
    }

    // --- Defense: onlyOwner updates metadata (preferably immutable)
    function updateMetadataSecure(string calldata n, string calldata s) external onlyOwner {
        name = n; symbol = s;
        emit MetadataUpdated(n, s);
    }
}
