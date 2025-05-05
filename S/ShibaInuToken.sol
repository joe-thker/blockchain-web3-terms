// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SHIBSuite
/// @notice Implements CoreToken, TaxedToken, and StakingPool for Shiba Inu (SHIB)
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

/// 1) ERC20 Core Token
contract SHIBCore is Base {
    string public name = "Shiba Inu";
    string public symbol = "SHIB";
    uint8  public decimals = 18;
    uint256 public totalSupply;
    uint256 public cap = 1e27; // 1 billion * 1e18

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Attack: anyone can mint unlimited SHIB
    function mintInsecure(address to, uint256 amt) external {
        totalSupply += amt;
        balanceOf[to] += amt;
    }

    // --- Defense: onlyOwner + cap enforcement
    function mintSecure(address to, uint256 amt) external onlyOwner {
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

    // Insecure approve vulnerable to front-run
    function approveInsecure(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        return true;
    }

    // Secure increase/decrease
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
}

/// 2) Taxed Transfer Mechanism
contract SHIBTaxed is SHIBCore, ReentrancyGuard {
    address public treasury;
    uint256 public feeBP = 100;  // 1%

    mapping(address => bool) public feeExempt;

    // --- Attack: set treasury to zero address, bypass fees
    function setTreasuryInsecure(address t) external {
        treasury = t;
    }
    // --- Defense: onlyOwner + nonzero
    function setTreasurySecure(address t) external onlyOwner {
        require(t != address(0), "Zero address");
        treasury = t;
    }

    function setFeeBP(uint256 bp) external onlyOwner {
        require(bp <= 1000, "Max 10%");
        feeBP = bp;
    }

    // --- Attack: transfer ignoring fee or exempt logic
    function transferInsecure(address to, uint256 amt) external returns (bool) {
        // no fee taken
        return super.transfer(to, amt);
    }

    // --- Defense: enforce fee + CEI + reentrancy guard
    function transferSecure(address to, uint256 amt) external nonReentrant returns (bool) {
        uint256 fee = (amt * feeBP) / 10000;
        uint256 net = amt - fee;
        require(balanceOf[msg.sender] >= amt, "Insufficient");
        // Effects
        balanceOf[msg.sender] -= amt;
        balanceOf[to] += net;
        balanceOf[treasury] += fee;
        return true;
    }

    // Fee exemption management
    function setFeeExempt(address acct, bool ok) external onlyOwner {
        feeExempt[acct] = ok;
    }
}

/// 3) Staking Rewards Pool
contract SHIBStaking is Base, ReentrancyGuard {
    SHIBCore public token;
    uint256 public rewardRatePerBlock = 1e18; // 1 SHIB per block

    struct StakeInfo {
        uint256 amount;
        uint256 sinceBlock;
        uint256 rewardDebt;
    }
    mapping(address => StakeInfo) public stakes;
    uint256 public minStakePeriod = 100; // blocks

    constructor(address shibAddr) {
        token = SHIBCore(shibAddr);
    }

    // --- Attack: stake and immediately withdraw
    function stakeInsecure(uint256 amt) external {
        require(token.balanceOf(msg.sender) >= amt, "No tokens");
        token.transfer(address(this), amt);
        stakes[msg.sender].amount += amt;
        // no timestamp
    }

    // --- Defense: CEI + record block + nonReentrant
    function stakeSecure(uint256 amt) external nonReentrant {
        require(token.balanceOf(msg.sender) >= amt, "No tokens");
        stakes[msg.sender].rewardDebt += pendingReward(msg.sender);
        stakes[msg.sender].amount    += amt;
        stakes[msg.sender].sinceBlock  = block.number;
        token.transfer(address(this), amt);
    }

    // Calculate pending rewards
    function pendingReward(address user) public view returns (uint256) {
        StakeInfo storage s = stakes[user];
        uint256 blocks = block.number - s.sinceBlock;
        return (s.amount * rewardRatePerBlock * blocks) / 1e18 - s.rewardDebt;
    }

    // --- Attack: withdraw ignoring period & reentrancy
    function withdrawInsecure() external {
        StakeInfo storage s = stakes[msg.sender];
        // no min period, no reentrancy guard
        uint256 bal = s.amount;
        uint256 rew = pendingReward(msg.sender);
        delete stakes[msg.sender];
        token.transfer(msg.sender, bal + rew);
    }

    // --- Defense: enforce min period + CEI + nonReentrant
    function withdrawSecure() external nonReentrant {
        StakeInfo storage s = stakes[msg.sender];
        require(s.amount > 0, "No stake");
        require(block.number >= s.sinceBlock + minStakePeriod, "Too soon");
        uint256 bal = s.amount;
        uint256 rew = pendingReward(msg.sender);
        // Effects
        delete stakes[msg.sender];
        // Interaction
        token.transfer(msg.sender, bal + rew);
    }
}
