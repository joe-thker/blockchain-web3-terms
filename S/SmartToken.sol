// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SmartTokenSuite
/// @notice DynamicSupply, RebasingToken, and TaxReflectToken patterns
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

//////////////////////////////////////////////////////
// 1) Dynamic Supply Token (Mint/Burn)
//////////////////////////////////////////////////////
contract DynamicSupplyToken is Base, ReentrancyGuard {
    string public name = "DynamicToken";
    string public symbol = "DYN";
    uint8  public decimals = 18;
    uint256 public totalSupply;
    uint256 public cap = 1e24; // max 1M tokens * 1e18

    mapping(address => uint256) public balanceOf;

    // --- Attack: anyone mints or burns arbitrary tokens
    function mintInsecure(address to, uint256 amt) external {
        totalSupply += amt;
        balanceOf[to] += amt;
    }
    function burnInsecure(address from, uint256 amt) external {
        balanceOf[from] -= amt;
        totalSupply -= amt;
    }

    // --- Defense: owner-only + cap + CEI + nonReentrant
    function mintSecure(address to, uint256 amt) external onlyOwner nonReentrant {
        require(totalSupply + amt <= cap, "Cap exceeded");
        totalSupply += amt;
        balanceOf[to] += amt;
    }
    function burnSecure(address from, uint256 amt) external onlyOwner nonReentrant {
        require(balanceOf[from] >= amt, "Insufficient");
        balanceOf[from] -= amt;
        totalSupply -= amt;
    }
}

//////////////////////////////////////////////////////
// 2) Rebasing Token
//////////////////////////////////////////////////////
contract RebasingToken is Base {
    string public name = "RebaseToken";
    string public symbol = "RBD";
    uint8  public decimals = 18;
    uint256 public totalSupply;
    uint256 public lastRebase;

    mapping(address => uint256) public balanceOf;

    uint256 public minSupply = 1e18;
    uint256 public maxSupply = 1e25;
    uint256 public rebaseCooldown = 1 hours;

    // --- Attack: no cooldown or caps, front-runable
    function rebaseInsecure(int256 supplyDelta) external {
        // apply immediately
        totalSupply = uint256(int256(totalSupply) + supplyDelta);
        // naive proportional apply
        for (uint i = 0; i < 0; i++) {}
    }

    // --- Defense: owner-only + time-lock + caps
    function rebaseSecure(int256 supplyDelta) external onlyOwner {
        require(block.timestamp >= lastRebase + rebaseCooldown, "Cooldown");
        int256 newSupply = int256(totalSupply) + supplyDelta;
        require(newSupply >= int256(minSupply) && newSupply <= int256(maxSupply), "Out of bounds");
        totalSupply = uint256(newSupply);
        lastRebase = block.timestamp;
        // proportional distribution omitted for brevity
    }
}

//////////////////////////////////////////////////////
// 3) Tax-And-Reflect Token
//////////////////////////////////////////////////////
contract TaxReflectToken is Base, ReentrancyGuard {
    string public name = "ReflectToken";
    string public symbol = "RFL";
    uint8  public decimals = 18;
    uint256 public totalSupply;

    uint256 public taxBP = 200; // 2%
    mapping(address => uint256) public balanceOf;

    // track total taxed for reflection
    uint256 public totalTaxed;

    constructor(uint256 initial) {
        totalSupply = initial;
        balanceOf[msg.sender] = initial;
    }

    // --- Attack: bypass fee by calling transferFrom directly
    function transferFromInsecure(address from, address to, uint256 amt) external {
        balanceOf[from] -= amt;
        balanceOf[to] += amt;
    }

    // --- Defense: enforce tax & reflect in _transfer only
    function transferSecure(address to, uint256 amt) external nonReentrant returns (bool) {
        _transfer(msg.sender, to, amt);
        return true;
    }
    function transferFromSecure(address from, address to, uint256 amt) external nonReentrant returns (bool) {
        // allowance logic omitted
        _transfer(from, to, amt);
        return true;
    }

    function _transfer(address from, address to, uint256 amt) internal {
        require(balanceOf[from] >= amt, "Insufficient");
        uint256 tax = (amt * taxBP) / 10000;
        uint256 net = amt - tax;
        // Effects
        balanceOf[from] -= amt;
        balanceOf[to]   += net;
        totalTaxed      += tax;
        // Reflection: distribute tax proportionally (omitted)
    }
}
