// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title BasicOffshoreAccount
 * @notice Deposit ETH, request a withdrawal, wait `lockPeriod`, then withdraw.
 *         Owner can pause all operations.
 */
contract BasicOffshoreAccount is Ownable, Pausable {
    mapping(address => uint256) public balances;

    struct WithdrawalRequest {
        uint256 amount;
        uint256 requestedAt;
    }
    mapping(address => WithdrawalRequest) public requests;

    uint256 public lockPeriod;

    event Deposited(address indexed user, uint256 amount);
    event WithdrawalRequested(address indexed user, uint256 amount, uint256 availableAt);
    event Withdrawn(address indexed user, uint256 amount);
    event LockPeriodUpdated(uint256 newLockPeriod);
    event RequestCancelled(address indexed user);

    constructor(uint256 initialLockPeriod) Ownable(msg.sender) {
        lockPeriod = initialLockPeriod;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setLockPeriod(uint256 newLockPeriod) external onlyOwner {
        lockPeriod = newLockPeriod;
        emit LockPeriodUpdated(newLockPeriod);
    }

    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Must deposit > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function requestWithdrawal(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        requests[msg.sender] = WithdrawalRequest({
            amount: amount,
            requestedAt: block.timestamp
        });
        emit WithdrawalRequested(msg.sender, amount, block.timestamp + lockPeriod);
    }

    function cancelRequest() external whenNotPaused {
        WithdrawalRequest storage req = requests[msg.sender];
        require(req.amount > 0, "No pending request");
        delete requests[msg.sender];
        emit RequestCancelled(msg.sender);
    }

    function withdraw() external whenNotPaused {
        WithdrawalRequest storage req = requests[msg.sender];
        uint256 amount = req.amount;
        require(amount > 0, "No pending request");
        require(block.timestamp >= req.requestedAt + lockPeriod, "Lock not expired");

        delete requests[msg.sender];
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function availableAt(address user) external view returns (uint256) {
        WithdrawalRequest storage req = requests[user];
        if (req.amount == 0) return 0;
        return req.requestedAt + lockPeriod;
    }
}
