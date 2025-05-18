// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract WeakHandsVault {
    IERC20 public immutable token;
    uint256 public immutable minHoldTime;
    uint256 public immutable penaltyRate; // e.g., 10% = 0.1e18

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Deposit) public deposits;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 penalty);

    constructor(address _token, uint256 _holdTime, uint256 _penaltyRate) {
        require(_penaltyRate <= 1e18, "Invalid penalty");
        token = IERC20(_token);
        minHoldTime = _holdTime;
        penaltyRate = _penaltyRate;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Zero deposit");
        token.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] = Deposit({
            amount: deposits[msg.sender].amount + amount,
            timestamp: block.timestamp
        });
        emit Deposited(msg.sender, amount);
    }

    function withdraw() external {
        Deposit memory d = deposits[msg.sender];
        require(d.amount > 0, "Nothing to withdraw");

        uint256 penalty = 0;
        if (block.timestamp < d.timestamp + minHoldTime) {
            penalty = (d.amount * penaltyRate) / 1e18;
        }

        uint256 payout = d.amount - penalty;
        delete deposits[msg.sender];

        if (penalty > 0) token.transfer(address(0), penalty); // burn
        token.transfer(msg.sender, payout);

        emit Withdrawn(msg.sender, payout, penalty);
    }

    function getPenalty(address user) external view returns (uint256) {
        Deposit memory d = deposits[user];
        if (block.timestamp >= d.timestamp + minHoldTime) return 0;
        return (d.amount * penaltyRate) / 1e18;
    }
}
