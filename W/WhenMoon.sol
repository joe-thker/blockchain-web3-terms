// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MoonHoldVault - Prevents early exit during "When Moon" hype, rewards patient holders
contract MoonHoldVault {
    IERC20 public immutable token;
    uint256 public immutable holdWindow;
    uint256 public immutable moonTaxRate; // e.g., 10% = 0.1e18

    struct Holder {
        uint256 amount;
        uint256 depositedAt;
        bool claimed;
    }

    mapping(address => Holder) public vault;

    event Deposited(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 received, uint256 tax);

    constructor(address _token, uint256 _holdWindow, uint256 _moonTaxRate) {
        require(_moonTaxRate <= 1e18, "Tax too high");
        token = IERC20(_token);
        holdWindow = _holdWindow;
        moonTaxRate = _moonTaxRate;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Zero");
        require(vault[msg.sender].amount == 0, "Already deposited");

        token.transferFrom(msg.sender, address(this), amount);
        vault[msg.sender] = Holder({
            amount: amount,
            depositedAt: block.timestamp,
            claimed: false
        });

        emit Deposited(msg.sender, amount);
    }

    function claim() external {
        Holder storage h = vault[msg.sender];
        require(!h.claimed, "Already claimed");
        require(h.amount > 0, "No deposit");

        uint256 timeHeld = block.timestamp - h.depositedAt;
        uint256 tax = 0;
        uint256 payout = h.amount;

        if (timeHeld < holdWindow) {
            tax = (h.amount * moonTaxRate) / 1e18;
            payout -= tax;
            token.transfer(address(0), tax); // burn tax
        }

        h.claimed = true;
        token.transfer(msg.sender, payout);
        emit Claimed(msg.sender, payout, tax);
    }

    function timeLeft(address user) external view returns (uint256) {
        Holder memory h = vault[user];
        if (block.timestamp >= h.depositedAt + holdWindow) return 0;
        return (h.depositedAt + holdWindow) - block.timestamp;
    }
}

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}
