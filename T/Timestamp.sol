// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TimestampModule - Solidity Timestamp Attack and Defense Examples

// ==============================
// 🔓 Timestamp Lottery (Vulnerable RNG)
// ==============================
contract TimestampLottery {
    address public winner;
    uint256 public lastPlay;

    function play() external payable {
        require(msg.value == 1 ether, "Must send 1 ETH");

        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10;
        if (rand == 7) {
            winner = msg.sender;
            payable(msg.sender).transfer(address(this).balance);
        }

        lastPlay = block.timestamp;
    }

    receive() external payable {}
}

// ==============================
// 🔓 Attacker: Predict Timestamp-Based RNG
// ==============================
interface ILottery {
    function play() external payable;
}

contract TimestampAttacker {
    ILottery public lottery;

    constructor(address _lottery) {
        lottery = ILottery(_lottery);
    }

    function attack() external payable {
        lottery.play{value: 1 ether}();
    }

    receive() external payable {}
}

// ==============================
// 🔐 Safe Timestamp Usage with Block-Based Conditions
// ==============================
abstract contract SafeRandom {
    function safeRand(address user, uint256 salt) public view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), user, salt));
    }
}

contract SafeTimestampLogic is SafeRandom {
    uint256 public immutable createdAt;
    uint256 public constant TIME_DELAY = 1 days;
    bool public triggered;

    constructor() {
        createdAt = block.timestamp;
    }

    function trigger() external {
        require(!triggered, "Already used");
        require(block.timestamp >= createdAt + TIME_DELAY, "Too soon");
        triggered = true;
    }

    function getRandom(bytes32 salt) external view returns (bytes32) {
        return safeRand(msg.sender, uint256(salt));
    }
}

// ==============================
// 🔐 Rate Limiter Using Timestamps
// ==============================
contract RateLimiter {
    mapping(address => uint256) public lastAction;
    uint256 public constant COOLDOWN = 60; // 60 seconds

    function use() external {
        require(block.timestamp > lastAction[msg.sender] + COOLDOWN, "Cooling down");
        lastAction[msg.sender] = block.timestamp;
    }
}
