// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PooledCloudMining {
    address public owner;
    // Reward rate: total mined tokens per second for the pool.
    uint256 public poolRewardRate;

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
        bool withdrawn;
    }
    mapping(address => Deposit) public deposits;
    uint256 public totalPool;

    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 principal, uint256 reward, uint256 timestamp);

    constructor(uint256 _poolRewardRate) {
        owner = msg.sender;
        poolRewardRate = _poolRewardRate;
    }

    /// @notice Deposit funds into the mining pool.
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be > 0");
        require(deposits[msg.sender].amount == 0, "Already deposited");
        deposits[msg.sender] = Deposit({
            amount: msg.value,
            timestamp: block.timestamp,
            withdrawn: false
        });
        totalPool += msg.value;
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    /// @notice Withdraw your deposit along with your share of rewards.
    function withdraw() external {
        Deposit storage d = deposits[msg.sender];
        require(d.amount > 0, "No deposit");
        require(!d.withdrawn, "Already withdrawn");
        uint256 duration = block.timestamp - d.timestamp;
        // Reward is proportional to your share of the pool.
        uint256 reward = (d.amount * poolRewardRate * duration) / totalPool;
        d.withdrawn = true;
        totalPool -= d.amount;
        emit Withdrawn(msg.sender, d.amount, reward, block.timestamp);
        (bool success, ) = msg.sender.call{value: d.amount}("");
        require(success, "Withdrawal failed");
        // In a real system, reward tokens would be distributed to the user.
    }
}
