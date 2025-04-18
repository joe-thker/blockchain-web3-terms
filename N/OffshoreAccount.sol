// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title OffshoreAccount
 * @notice A simple on‑chain “offshore account” with time‑locked withdrawals.
 *         Users can deposit Ether, request a withdrawal, and only withdraw after
 *         a configurable lock period. The contract owner (offshore bank) manages
 *         the lock period and may pause the contract in emergencies.
 */
contract OffshoreAccount is Ownable, Pausable {
    /// @notice User’s deposited balance
    mapping(address => uint256) public balances;

    /// @notice Withdrawal request data per user
    struct WithdrawalRequest {
        uint256 amount;
        uint256 timestamp;
    }
    mapping(address => WithdrawalRequest) public requests;

    /// @notice Lock period (seconds) between request and withdrawal
    uint256 public lockPeriod;

    event Deposited(address indexed user, uint256 amount);
    event WithdrawalRequested(address indexed user, uint256 amount, uint256 availableAt);
    event Withdrawn(address indexed user, uint256 amount);
    event LockPeriodUpdated(uint256 newLockPeriod);
    event RequestCanceled(address indexed user);

    /**
     * @param initialLockPeriod The initial lock period (in seconds) for withdrawals.
     */
    constructor(uint256 initialLockPeriod) Ownable(msg.sender) {
        lockPeriod = initialLockPeriod;
    }

    /// @notice Pause all operations. Only owner may call.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause operations. Only owner may call.
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Update the withdrawal lock period.
     * @param newLockPeriod The new lock period in seconds.
     */
    function setLockPeriod(uint256 newLockPeriod) external onlyOwner {
        lockPeriod = newLockPeriod;
        emit LockPeriodUpdated(newLockPeriod);
    }

    /**
     * @notice Deposit Ether into your offshore account.
     *         Increases your balance immediately.
     */
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "OffshoreAccount: deposit > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Fallback to accept direct ETH transfers as deposits.
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Request a withdrawal of up to `amount`.
     *         You may withdraw after `lockPeriod` seconds.
     * @param amount The amount of Ether to withdraw.
     */
    function requestWithdrawal(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "OffshoreAccount: insufficient balance");
        requests[msg.sender] = WithdrawalRequest({
            amount: amount,
            timestamp: block.timestamp
        });
        emit WithdrawalRequested(
            msg.sender,
            amount,
            block.timestamp + lockPeriod
        );
    }

    /**
     * @notice Cancel your pending withdrawal request.
     */
    function cancelRequest() external whenNotPaused {
        WithdrawalRequest storage req = requests[msg.sender];
        require(req.amount > 0, "OffshoreAccount: no pending request");
        delete requests[msg.sender];
        emit RequestCanceled(msg.sender);
    }

    /**
     * @notice Execute your pending withdrawal after the lock period.
     */
    function withdraw() external whenNotPaused {
        WithdrawalRequest storage req = requests[msg.sender];
        uint256 amount = req.amount;
        require(amount > 0, "OffshoreAccount: no pending request");
        require(
            block.timestamp >= req.timestamp + lockPeriod,
            "OffshoreAccount: lock period not passed"
        );

        // Effects
        delete requests[msg.sender];
        balances[msg.sender] -= amount;

        // Interaction
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Check when your requested withdrawal becomes available.
     * @return availableAt Timestamp when you can call `withdraw()`.
     */
    function availableAt(address user) external view returns (uint256) {
        WithdrawalRequest storage req = requests[user];
        if (req.amount == 0) return 0;
        return req.timestamp + lockPeriod;
    }
}
