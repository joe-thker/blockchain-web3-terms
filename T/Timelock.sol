// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TimelockModule - Secure and Insecure Timelock Implementations in Solidity

// ==============================
// 🔓 Insecure Timelock Contract (Bypassable)
// ==============================
contract InsecureTimelock {
    uint256 public unlockTime;
    bool public isUnlocked;

    constructor(uint256 delaySeconds) {
        unlockTime = block.timestamp + delaySeconds;
        isUnlocked = false;
    }

    function toggleUnlock() external {
        // Dangerous — allows manual override
        isUnlocked = true;
    }

    function withdraw() external {
        require(block.timestamp >= unlockTime || isUnlocked, "Still locked");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}

// ==============================
// 🔓 Timelock Attacker (Bypass / Reentrancy)
// ==============================
interface ITimelock {
    function toggleUnlock() external;
    function withdraw() external;
}

contract TimelockAttacker {
    ITimelock public target;

    constructor(address _target) {
        target = ITimelock(_target);
    }

    function attack() external {
        target.toggleUnlock(); // Bypass
        target.withdraw();
    }

    receive() external payable {}
}

// ==============================
// 🔐 Secure Timelock With Immutable Delay
// ==============================
abstract contract ReentrancyGuard {
    bool internal locked;

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
}

contract SecureTimelock is ReentrancyGuard {
    address public immutable beneficiary;
    uint256 public immutable unlockTime;
    bool public claimed;

    event Locked(address indexed to, uint256 until);
    event Unlocked(address indexed to, uint256 amount);

    constructor(address _beneficiary, uint256 delaySeconds) payable {
        beneficiary = _beneficiary;
        unlockTime = block.timestamp + delaySeconds;
        emit Locked(_beneficiary, unlockTime);
    }

    function withdraw() external nonReentrant {
        require(msg.sender == beneficiary, "Not owner");
        require(block.timestamp >= unlockTime, "Still locked");
        require(!claimed, "Already claimed");

        claimed = true;
        uint256 amt = address(this).balance;
        payable(msg.sender).transfer(amt);
        emit Unlocked(msg.sender, amt);
    }

    receive() external payable {}
}
