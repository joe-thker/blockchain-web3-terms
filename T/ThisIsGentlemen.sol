// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title GentlemenModule - Meme-Based Solidity Pattern for Honor Commitments and Anti-Rug Protection

// ==============================
// 🔐 Gentlemen Vault With Hard Timelock
// ==============================
contract GentlemenVault {
    address public immutable lpToken;
    uint256 public immutable unlockTime;
    address public immutable beneficiary;

    event HonorableLock(address indexed token, uint256 unlockAt);
    event GentlemenExit(address indexed to, uint256 amount);

    constructor(address _lpToken, uint256 _duration, address _beneficiary) {
        lpToken = _lpToken;
        unlockTime = block.timestamp + _duration;
        beneficiary = _beneficiary;

        emit HonorableLock(_lpToken, unlockTime);
    }

    function withdraw() external {
        require(block.timestamp >= unlockTime, "Too soon");
        uint256 balance = IERC20(lpToken).balanceOf(address(this));
        IERC20(lpToken).transfer(beneficiary, balance);
        emit GentlemenExit(beneficiary, balance);
    }
}

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

// ==============================
// 🔓 Fake Gentlemen With Override Exit
// ==============================
contract FakeGentlemen {
    address public owner;
    address public lpToken;

    constructor(address _lpToken) {
        owner = msg.sender;
        lpToken = _lpToken;
    }

    function rug() external {
        require(msg.sender == owner, "Not owner");
        uint256 balance = IERC20(lpToken).balanceOf(address(this));
        IERC20(lpToken).transfer(owner, balance);
    }
}

// ==============================
// 🔐 GentlemenGuard - Public Meme Attestation
// ==============================
contract GentlemenGuard {
    event GentlemenRegistered(address user, string reason);
    mapping(address => bool) public isGentle;

    function declareHonor(string calldata reason) external {
        isGentle[msg.sender] = true;
        emit GentlemenRegistered(msg.sender, reason);
    }

    function isHonorable(address user) external view returns (bool) {
        return isGentle[user];
    }
}

// ==============================
// 🔓 Meme Attacker: Pretends Then Rugs
// ==============================
interface IGentlemenVault {
    function withdraw() external;
}

contract MemeAttacker {
    IGentlemenVault public vault;
    bool public pretendToBeGentleman;

    constructor(address _vault) {
        vault = IGentlemenVault(_vault);
    }

    function fakeIt() external {
        pretendToBeGentleman = true;
    }

    function attack() external {
        vault.withdraw();
    }
}
