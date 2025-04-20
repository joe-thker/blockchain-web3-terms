// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * OpenFiStakingVault
 * – Stake OFT to share protocol revenue (paid in DAI).
 * – Auto‑compounds: whenever revenue is added, a global
 *   `accRewardPerShare` is updated; users claim on withdraw.
 */
contract OpenFiStakingVault is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable OFT;
    IERC20 public immutable DAI;

    uint256 public totalStaked;
    uint256 public accRewardPerShare;      // 1e18 precision

    struct User {
        uint256 amount;                    // OFT staked
        uint256 rewardDebt;                // for reward accounting
    }
    mapping(address => User) public users;

    event Deposit(address indexed u, uint256 amt);
    event Withdraw(address indexed u, uint256 amt, uint256 reward);
    event RevenueAdded(uint256 amt);

    constructor(IERC20 oft, IERC20 dai) Ownable(msg.sender) {
        OFT = oft;
        DAI = dai;
    }

    /* ───── protocol pays revenue ───── */
    function addRevenue(uint256 amount) external {
        DAI.safeTransferFrom(msg.sender, address(this), amount);
        if (totalStaked > 0) {
            accRewardPerShare += (amount * 1e18) / totalStaked;
        }
        emit RevenueAdded(amount);
    }

    /* ───── stake / unstake ───── */
    function deposit(uint256 amount) external {
        User storage u = users[msg.sender];
        _harvest(u);

        OFT.safeTransferFrom(msg.sender, address(this), amount);
        u.amount += amount;
        totalStaked += amount;
        u.rewardDebt = (u.amount * accRewardPerShare) / 1e18;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        User storage u = users[msg.sender];
        require(u.amount >= amount, "too much");
        _harvest(u);

        u.amount -= amount;
        totalStaked -= amount;
        u.rewardDebt = (u.amount * accRewardPerShare) / 1e18;

        OFT.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, 0);
    }

    /* ───── view helper ───── */
    function pendingReward(address user) external view returns (uint256) {
        User storage u = users[user];
        uint256 crps = accRewardPerShare;
        return (u.amount * crps) / 1e18 - u.rewardDebt;
    }

    /* ───── internal ───── */
    function _harvest(User storage u) private {
        uint256 pending = (u.amount * accRewardPerShare) / 1e18 - u.rewardDebt;
        if (pending > 0) {
            DAI.safeTransfer(msg.sender, pending);
        }
    }
}
