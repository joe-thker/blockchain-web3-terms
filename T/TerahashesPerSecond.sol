// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TerahashModule - Simulated TH/s Mining System with Attack and Defense in Solidity

// ==============================
// 🔓 Basic Mining Game (PoW Simulation)
// ==============================
contract PoWMiningGame {
    bytes32 public currentChallenge;
    uint256 public difficulty;
    uint256 public reward = 0.01 ether;

    mapping(address => uint256) public balances;

    event Mined(address miner, uint256 reward);

    constructor() {
        difficulty = 2**240; // easy for test
        currentChallenge = blockhash(block.number - 1);
    }

    function mine(uint256 nonce) external {
        bytes32 hashResult = keccak256(abi.encodePacked(currentChallenge, msg.sender, nonce));
        require(uint256(hashResult) < difficulty, "Invalid proof");

        currentChallenge = hashResult;
        balances[msg.sender] += reward;
        emit Mined(msg.sender, reward);
    }

    function claim() external {
        uint256 amt = balances[msg.sender];
        require(amt > 0, "Nothing");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amt);
    }

    receive() external payable {}
}

// ==============================
// 🔓 Fake Miner / Proof Spoofer
// ==============================
interface IMine {
    function mine(uint256 nonce) external;
}

contract FakeMinerAttack {
    IMine public powGame;

    constructor(address _target) {
        powGame = IMine(_target);
    }

    function trySpoof(uint256 precomputedNonce) external {
        powGame.mine(precomputedNonce);
    }
}

// ==============================
// 🔐 Safe PoW Miner with Effort Verification
// ==============================
contract SafePoWMiner {
    bytes32 public challenge;
    uint256 public difficulty;
    uint256 public reward = 0.01 ether;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastGasUsed;
    uint256 public totalMines;
    uint256 public gasBaseline = 50000;

    event Mined(address miner, uint256 effort, uint256 reward);

    constructor() {
        difficulty = 2**240;
        challenge = keccak256(abi.encodePacked(blockhash(block.number - 1)));
    }

    function mine(uint256 nonce) external {
        uint256 startGas = gasleft();
        bytes32 result = keccak256(abi.encodePacked(challenge, msg.sender, nonce));
        require(uint256(result) < difficulty, "Invalid");

        challenge = result;
        balances[msg.sender] += reward;
        totalMines++;
        lastGasUsed[msg.sender] = gasBaseline + (startGas - gasleft());

        emit Mined(msg.sender, lastGasUsed[msg.sender], reward);
    }

    function claim() external {
        uint256 amt = balances[msg.sender];
        require(amt > 0, "Empty");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amt);
    }

    function getEffort(address miner) external view returns (uint256) {
        return lastGasUsed[miner];
    }

    receive() external payable {}
}

// ==============================
// ⚙️ Difficulty Manager
// ==============================
contract DifficultyManager {
    uint256 public difficulty = 2**240;
    uint256 public interval = 10;
    uint256 public lastAdjustBlock;
    uint256 public mineRate;

    function adjustDifficulty(uint256 recentMines) external {
        if (block.number <= lastAdjustBlock + interval) return;
        if (recentMines > interval) {
            difficulty = difficulty * 110 / 100; // harder
        } else {
            difficulty = difficulty * 90 / 100; // easier
        }
        lastAdjustBlock = block.number;
    }

    function getDifficulty() external view returns (uint256) {
        return difficulty;
    }
}
