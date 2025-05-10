// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TapToEarnModule - Attack and Defense Implementation for Tap-to-Earn Crypto Games

// ==============================
// 🔓 Vulnerable Tap-to-Earn Game
// ==============================
contract TapGame {
    mapping(address => uint256) public taps;
    mapping(address => uint256) public rewards;

    event Tapped(address indexed user, uint256 totalTaps);

    function tap() external {
        taps[msg.sender] += 1;
        rewards[msg.sender] += 1e15; // 0.001 ETH
        emit Tapped(msg.sender, taps[msg.sender]);
    }

    function claim() external {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "Nothing to claim");
        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}

// ==============================
// 🔓 Attack Contract: Bot Spammer
// ==============================
interface ITapGame {
    function tap() external;
    function claim() external;
}

contract TapBotAttack {
    ITapGame public game;

    constructor(address _game) {
        game = ITapGame(_game);
    }

    function farmTaps(uint256 times) external {
        for (uint256 i = 0; i < times; i++) {
            game.tap();
        }
    }

    function drain() external {
        game.claim();
    }

    receive() external payable {}
}

// ==============================
// 🔐 Safe Tap Game With Defenses
// ==============================
contract SafeTapGame {
    mapping(address => uint256) public taps;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastTapBlock;
    mapping(address => bool) public banned;

    uint256 public constant COOLDOWN_BLOCKS = 3;
    uint256 public constant MAX_TAPS = 100;
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "Reentrant detected");
        locked = true;
        _;
        locked = false;
    }

    event SafeTapped(address indexed user, uint256 totalTaps);

    function tap() external noReentrant {
        require(!banned[msg.sender], "Bot banned");
        require(block.number > lastTapBlock[msg.sender] + COOLDOWN_BLOCKS, "Tap cooldown");
        require(taps[msg.sender] < MAX_TAPS, "Tap limit");

        lastTapBlock[msg.sender] = block.number;
        taps[msg.sender] += 1;
        rewards[msg.sender] += 1e15;

        emit SafeTapped(msg.sender, taps[msg.sender]);
    }

    function claim() external noReentrant {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "No reward");
        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function ban(address user) external {
        // Assume admin-only in production
        banned[user] = true;
    }

    receive() external payable {}
}

// ==============================
// 🧪 Mock Bot Detection Module
// ==============================
contract BotDetector {
    mapping(address => uint256) public gasUsed;

    function checkGas(address user) external view returns (bool) {
        return gasUsed[user] < 100_000; // Fake threshold for bot signature
    }

    function recordGas(address user, uint256 gasAmount) external {
        gasUsed[user] = gasAmount;
    }
}
