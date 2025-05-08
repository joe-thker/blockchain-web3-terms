// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address,a ddress,uint256) external returns(bool);
    function transfer(address,uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
}

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// ---------------------------------------------
/// 1) Simple Token Staking Vault
/// ---------------------------------------------
contract SimpleStaking is ReentrancyGuard {
    IERC20 public stakingToken;
    uint256 public rewardRate; // per second per token staked, fixed

    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastTimestamp;
    }
    mapping(address=>StakeInfo) public stakes;

    constructor(IERC20 _token, uint256 _rate) {
        stakingToken = _token;
        rewardRate   = _rate;
    }

    // --- Attack: deposit updates amount but not rewardDebt
    function depositInsecure(uint256 amt) external {
        stakingToken.transferFrom(msg.sender, address(this), amt);
        StakeInfo storage s = stakes[msg.sender];
        s.amount += amt;
        // no reward accounting => can withdraw more later
    }

    // --- Defense: update rewards before changing stake
    function depositSecure(uint256 amt) external nonReentrant {
        StakeInfo storage s = stakes[msg.sender];
        // 1) accrue pending rewards
        uint256 pending = (block.timestamp - s.lastTimestamp) * s.amount * rewardRate;
        s.rewardDebt += pending;
        // 2) transfer in
        stakingToken.transferFrom(msg.sender, address(this), amt);
        s.amount       += amt;
        s.lastTimestamp = block.timestamp;
    }

    // --- Attack: withdraw without CEI
    function withdrawInsecure(uint256 amt) external {
        StakeInfo storage s = stakes[msg.sender];
        require(s.amount >= amt, "Insufficient");
        // interaction before effect
        stakingToken.transfer(msg.sender, amt);
        s.amount -= amt;
    }

    // --- Defense: CEI + reward update + nonReentrant
    function withdrawSecure(uint256 amt) external nonReentrant {
        StakeInfo storage s = stakes[msg.sender];
        require(s.amount >= amt, "Insufficient");
        // 1) accrue rewards
        uint256 pending = (block.timestamp - s.lastTimestamp) * s.amount * rewardRate;
        s.rewardDebt += pending;
        s.lastTimestamp = block.timestamp;
        // 2) Effects
        s.amount -= amt;
        // 3) Interaction
        stakingToken.transfer(msg.sender, amt);
    }

    // claim rewards
    function claimRewards() external nonReentrant {
        StakeInfo storage s = stakes[msg.sender];
        uint256 pending = (block.timestamp - s.lastTimestamp) * s.amount * rewardRate;
        uint256 toClaim = s.rewardDebt + pending;
        require(toClaim > 0, "No rewards");
        s.rewardDebt    = 0;
        s.lastTimestamp = block.timestamp;
        stakingToken.transfer(msg.sender, toClaim);
    }
}

/// ---------------------------------------------
/// 2) Delegated Staking (Operator Model)
/// ---------------------------------------------
contract DelegatedStaking is ReentrancyGuard {
    IERC20 public stakingToken;
    address public operator;

    struct Delegation {
        uint256 amount;
        bool     slashed;
    }
    mapping(address=>Delegation) public delegations;

    modifier onlyDelegator(address delegator) {
        require(msg.sender == delegator, "Not delegator");
        _;
    }

    constructor(IERC20 _token, address _operator) {
        stakingToken = _token;
        operator     = _operator;
    }

    // --- Attack: anyone stakes on behalf of someone else
    function delegateInsecure(address delegator, uint256 amt) external {
        stakingToken.transferFrom(delegator, address(this), amt);
        delegations[delegator].amount += amt;
    }

    // --- Defense: only delegator can delegate to operator
    function delegateSecure(uint256 amt) external {
        stakingToken.transferFrom(msg.sender, address(this), amt);
        delegations[msg.sender].amount += amt;
    }

    // operator stakes aggregated tokens off-chain...

    // --- Attack: no slash protection
    function slashInsecure(address delegator) external {
        require(msg.sender == operator, "No"); 
        delegations[delegator].amount = 0;
    }

    // --- Defense: mark slashed and defer withdrawal
    function slashSecure(address delegator, uint256 penalty) external {
        require(msg.sender == operator, "No");
        Delegation storage d = delegations[delegator];
        require(!d.slashed, "Already slashed");
        // reduce by penalty
        uint256 amt = d.amount;
        d.amount = amt > penalty ? amt - penalty : 0;
        d.slashed = true;
    }

    // withdraw after slash
    function withdrawDelegation() external nonReentrant onlyDelegator(msg.sender) {
        Delegation storage d = delegations[msg.sender];
        uint256 amt = d.amount;
        require(amt > 0, "Nothing");
        d.amount = 0;
        stakingToken.transfer(msg.sender, amt);
    }
}

/// ---------------------------------------------
/// 3) Liquid Staking Derivative
/// ---------------------------------------------
contract LiquidStaking is ReentrancyGuard {
    IERC20 public stakingToken;
    IERC20 public sToken;  // liquid derivative

    constructor(IERC20 _stake, IERC20 _sToken) {
        stakingToken = _stake;
        sToken       = _sToken;
    }

    // --- Attack: mint sToken without staking underlying
    function mintInsecure(uint256 amt) external {
        // no stakingToken.transferFrom check
        // assume sToken.mint(msg.sender, amt);
    }

    // --- Defense: enforce 1:1 backing and CEI
    function mintSecure(uint256 amt) external nonReentrant {
        // 1) pull underlying
        stakingToken.transferFrom(msg.sender, address(this), amt);
        // 2) mint derivative
        // sToken.mint(msg.sender, amt);
    }

    // --- Attack: burn sToken and withdraw more than backing
    function burnInsecure(uint256 amt) external {
        // assume sToken.burnFrom(msg.sender, amt);
        stakingToken.transfer(msg.sender, amt * 2);  // malicious
    }

    // --- Defense: 1:1 exchange + nonReentrant
    function burnSecure(uint256 amt) external nonReentrant {
        // sToken.burnFrom(msg.sender, amt);
        stakingToken.transfer(msg.sender, amt);
    }
}
