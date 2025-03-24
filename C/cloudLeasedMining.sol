// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title LeasedCloudMining
/// @notice A simulation of leased cloud mining where users lock funds for a fixed term to earn rewards.
contract LeasedCloudMining {
    address public owner;
    // Reward rate: mined tokens per wei per second for the lease duration.
    uint256 public leaseRewardRate;

    struct Lease {
        uint256 amount;
        uint256 leaseStart;
        uint256 leaseEnd;
        bool claimed;
    }
    mapping(address => Lease[]) public leases;

    event LeaseCreated(address indexed user, uint256 amount, uint256 leaseStart, uint256 leaseEnd);
    event LeaseClaimed(address indexed user, uint256 amount, uint256 reward, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor(uint256 _leaseRewardRate) {
        owner = msg.sender;
        leaseRewardRate = _leaseRewardRate;
    }

    /// @notice Lease mining by locking funds for a specified duration.
    /// @param duration The lease duration in seconds.
    function leaseMining(uint256 duration) external payable {
        require(msg.value > 0, "Must deposit > 0");
        require(duration > 0, "Duration must be > 0");
        leases[msg.sender].push(Lease({
            amount: msg.value,
            leaseStart: block.timestamp,
            leaseEnd: block.timestamp + duration,
            claimed: false
        }));
        emit LeaseCreated(msg.sender, msg.value, block.timestamp, block.timestamp + duration);
    }

    /// @notice After the lease period, claim your deposit along with accrued rewards.
    /// @param index The index of the lease.
    function claimLease(uint256 index) external {
        require(index < leases[msg.sender].length, "Invalid index");
        Lease storage l = leases[msg.sender][index];
        require(!l.claimed, "Already claimed");
        require(block.timestamp >= l.leaseEnd, "Lease period not ended");
        l.claimed = true;
        uint256 duration = l.leaseEnd - l.leaseStart;
        uint256 reward = l.amount * leaseRewardRate * duration;
        emit LeaseClaimed(msg.sender, l.amount, reward, block.timestamp);
        // Return the deposit to the user.
        (bool success, ) = msg.sender.call{value: l.amount}("");
        require(success, "Refund transfer failed");
        // In practice, reward tokens might be minted.
    }
}
