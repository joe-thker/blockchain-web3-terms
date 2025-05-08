// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title StakingPoolSuite
/// @notice BasicPool, RewardPool, AutoCompoundPool with insecure vs. secure methods

////////////////////////////////////////////////////////////////////////////////
// 1) Basic Staking Pool
////////////////////////////////////////////////////////////////////////////////
contract BasicPool is ReentrancyGuard {
    IERC20 public stakingToken;
    uint256 public totalStaked;
    mapping(address=>uint256) public balance;
    mapping(address=>uint256) public rewardDebt;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    uint256 public rewardRate; // tokens per second

    constructor(IERC20 _stake, uint256 _rate) {
        stakingToken = _stake;
        rewardRate   = _rate;
    }

    // --- Attack: naive stake updates amount but not rewards
    function stakeInsecure(uint256 amt) external {
        stakingToken.transferFrom(msg.sender, address(this), amt);
        balance[msg.sender] += amt;
        totalStaked       += amt;
    }

    // --- Defense: update reward accounting before stake
    function stakeSecure(uint256 amt) external nonReentrant {
        _updateReward(msg.sender);
        stakingToken.transferFrom(msg.sender, address(this), amt);
        balance[msg.sender] += amt;
        totalStaked       += amt;
    }

    // --- Attack: reentrant unstake
    function unstakeInsecure(uint256 amt) external {
        require(balance[msg.sender]>=amt, "Insufficient");
        stakingToken.transfer(msg.sender, amt);
        balance[msg.sender]-=amt;
        totalStaked      -=amt;
    }

    // --- Defense: CEI + update rewards + nonReentrant
    function unstakeSecure(uint256 amt) external nonReentrant {
        _updateReward(msg.sender);
        require(balance[msg.sender]>=amt, "Insufficient");
        balance[msg.sender]-=amt;
        totalStaked      -=amt;
        stakingToken.transfer(msg.sender, amt);
    }

    // Claim rewards
    function claim() external nonReentrant {
        _updateReward(msg.sender);
        uint256 reward = rewardDebt[msg.sender];
        require(reward>0, "No reward");
        rewardDebt[msg.sender]=0;
        stakingToken.transfer(msg.sender, reward);
    }

    function _updateReward(address user) internal {
        if (totalStaked>0) {
            rewardPerTokenStored += (block.timestamp - lastUpdateTime)*rewardRate*1e18/totalStaked;
        }
        lastUpdateTime = block.timestamp;
        // user accounting
        uint256 earned = balance[user]*(rewardPerTokenStored - rewardDebt[user])/1e18;
        rewardDebt[user] = rewardPerTokenStored;
        rewardDebt[user] += earned;
    }
}

////////////////////////////////////////////////////////////////////////////////
// 2) Reward Distribution Pool
////////////////////////////////////////////////////////////////////////////////
contract RewardPool is ReentrancyGuard {
    IERC20 public stakingToken;
    IERC20[] public rewardTokens;
    mapping(IERC20=>uint256) public rewardPerTokenStored;
    mapping(IERC20=>mapping(address=>uint256)) public userRewardDebt;
    uint256 public totalStaked;
    mapping(address=>uint256) public balance;

    constructor(IERC20 _stake, IERC20[] memory _rewards) {
        stakingToken  = _stake;
        rewardTokens  = _rewards;
    }

    // --- Attack: deposit without updating any reward state
    function depositInsecure(uint256 amt) external {
        stakingToken.transferFrom(msg.sender, address(this), amt);
        balance[msg.sender]+=amt;
        totalStaked     +=amt;
    }

    // --- Defense: update all rewards before deposit
    function depositSecure(uint256 amt) external nonReentrant {
        _updateAllRewards(msg.sender);
        stakingToken.transferFrom(msg.sender, address(this), amt);
        balance[msg.sender]+=amt;
        totalStaked     +=amt;
    }

    // Harvest all
    function harvest() external nonReentrant {
        _updateAllRewards(msg.sender);
        for (uint i=0; i<rewardTokens.length; i++){
            IERC20 tok = rewardTokens[i];
            uint256 owed = userRewardDebt[tok][msg.sender];
            if (owed>0){
                userRewardDebt[tok][msg.sender]=0;
                tok.transfer(msg.sender, owed);
            }
        }
    }

    function _updateAllRewards(address user) internal {
        for (uint i=0; i<rewardTokens.length; i++){
            IERC20 tok = rewardTokens[i];
            uint256 bal = totalStaked>0
                ? tok.balanceOf(address(this))*1e18/totalStaked
                : 0;
            rewardPerTokenStored[tok] = bal;
            uint256 earned = balance[user]*(bal - userRewardDebt[tok][user])/1e18;
            userRewardDebt[tok][user] = bal;
            userRewardDebt[tok][user] += earned;
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
// 3) Auto-Compounding Pool
////////////////////////////////////////////////////////////////////////////////
interface ITWAP { function twap() external view returns(uint256); }

contract AutoCompound is ReentrancyGuard {
    IERC20 public stakingToken;
    ITWAP   public priceOracle;
    uint256 public lastCompound;
    uint256 public compoundInterval; // e.g. 1 day
    uint256 public maxSlippageBP;    //  max slippage

    constructor(IERC20 _stake, ITWAP _oracle, uint256 _interval, uint256 _slip) {
        stakingToken     = _stake;
        priceOracle      = _oracle;
        compoundInterval = _interval;
        maxSlippageBP    = _slip;
        lastCompound     = block.timestamp;
    }

    // --- Attack: anyone can compound repeatedly or flash-loan manipulate price
    function compoundInsecure() external {
        // no schedule, no price check
        uint256 reward = stakingToken.balanceOf(address(this))/10; 
        stakingToken.transfer(address(this), reward);
    }

    // --- Defense: onlyOwner, interval, TWAP slippage guard
    function compoundSecure() external onlyOwner nonReentrant {
        require(block.timestamp >= lastCompound + compoundInterval, "Too soon");
        uint256 price = priceOracle.twap();
        require(price>0, "Bad price");
        // slippage bound example vs last price (omitted)
        uint256 reward = stakingToken.balanceOf(address(this))/10;
        // cap per compound
        uint256 cap = stakingToken.balanceOf(address(this))/100;
        if (reward>cap) reward=cap;
        // reinvest
        stakingToken.transfer(address(this), reward);
        lastCompound = block.timestamp;
    }
}
