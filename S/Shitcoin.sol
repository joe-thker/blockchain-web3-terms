// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ShitcoinSuite
/// @notice Implements UnlimitedMintToken, HoneypotToken, and ExitScamToken patterns
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Basic reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Unlimited-Mint Shitcoin
contract UnlimitedMintToken is Base {
    string public name = "UnlimitedMint Shitcoin";
    string public symbol = "UMSHIT";
    uint8  public decimals = 18;
    uint256 public totalSupply;
    uint256 public cap = 1e24; // 1M * 1e18

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Attack: anyone can mint infinite tokens
    function mintInsecure(address to, uint256 amt) external {
        totalSupply += amt;
        balanceOf[to] += amt;
    }

    // --- Defense: onlyOwner + cap + optional timelock
    uint256 public mintingEnabledAfter = block.timestamp + 1 days;
    function mintSecure(address to, uint256 amt) external onlyOwner {
        require(block.timestamp >= mintingEnabledAfter, "Mint locked");
        require(totalSupply + amt <= cap, "Cap exceeded");
        totalSupply += amt;
        balanceOf[to] += amt;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balanceOf[msg.sender] >= amt, "Insufficient");
        balanceOf[msg.sender] -= amt;
        balanceOf[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }
    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(balanceOf[from] >= amt && allowance[from][msg.sender] >= amt, "Not allowed");
        allowance[from][msg.sender] -= amt;
        balanceOf[from] -= amt;
        balanceOf[to] += amt;
        return true;
    }
}

/// 2) Honeypot Token
contract HoneypotToken is Base {
    string public name = "Honeypot Shitcoin";
    string public symbol = "HONEYPOT";
    uint8  public decimals = 18;
    uint256 public totalSupply = 1e21; // fixed 1,000 tokens

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[owner] = totalSupply;
    }

    // --- Attack: transfer works only to owner, all other transfers revert
    function transferInsecure(address to, uint256 amt) external returns (bool) {
        require(to == owner, "Sell blocked");  // only owner can receive
        require(balanceOf[msg.sender] >= amt, "Insufficient");
        balanceOf[msg.sender] -= amt;
        balanceOf[to] += amt;
        return true;
    }

    // --- Defense: standard ERC20 transfer
    function transferSecure(address to, uint256 amt) external returns (bool) {
        require(balanceOf[msg.sender] >= amt, "Insufficient");
        balanceOf[msg.sender] -= amt;
        balanceOf[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }
    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(allowance[from][msg.sender] >= amt, "Not allowed");
        require(balanceOf[from] >= amt, "Insufficient");
        allowance[from][msg.sender] -= amt;
        balanceOf[from]     -= amt;
        balanceOf[to]       += amt;
        return true;
    }
}

/// 3) Exit-Scam Token with Liquidity Drain
contract ExitScamToken is Base, ReentrancyGuard {
    string public name = "ExitScam Shitcoin";
    string public symbol = "ESCAM";
    uint8  public decimals = 18;
    uint256 public totalSupply = 1e21;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() payable {
        balanceOf[owner] = totalSupply;
    }

    // --- Attack: owner can drain all ETH from contract anytime
    function withdrawLiquidityInsecure() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // --- Defense: timelock & disable after one use
    uint256 public liquidityUnlockTime = block.timestamp + 7 days;
    bool    public liquidityWithdrawn;
    function withdrawLiquiditySecure() external onlyOwner nonReentrant {
        require(!liquidityWithdrawn, "Already withdrawn");
        require(block.timestamp >= liquidityUnlockTime, "Locked");
        liquidityWithdrawn = true;
        payable(owner).transfer(address(this).balance);
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        require(balanceOf[msg.sender] >= amt, "Insufficient");
        balanceOf[msg.sender] -= amt;
        balanceOf[to] += amt;
        return true;
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }
    function transferFrom(address from, address to, uint256 amt) external returns (bool) {
        require(allowance[from][msg.sender] >= amt, "Not allowed");
        require(balanceOf[from] >= amt, "Insufficient");
        allowance[from][msg.sender] -= amt;
        balanceOf[from]     -= amt;
        balanceOf[to]       += amt;
        return true;
    }

    receive() external payable {}
}
