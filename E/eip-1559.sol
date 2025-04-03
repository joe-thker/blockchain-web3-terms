// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title EIP1559Simulator
/// @notice This contract simulates an EIP-1559–style fee mechanism for a DApp service.
/// Users call performAction() and must pay a fee that includes a dynamic base fee plus an optional tip.
/// At the end of a time period, the base fee is adjusted based on the number of actions performed relative to a target.
/// The tip (if any) is forwarded to a designated feeRecipient.
contract EIP1559Simulator is Ownable, ReentrancyGuard {
    /// @notice The dynamic base fee (in wei) that must be paid for each action.
    uint256 public baseFee;
    /// @notice The target number of transactions per period.
    uint256 public targetTxCount;
    /// @notice The number of transactions performed in the current period.
    uint256 public txCount;
    /// @notice Timestamp marking the start of the current period.
    uint256 public periodStart;
    /// @notice Duration of each period in seconds.
    uint256 public periodLength;
    /// @notice The address that will receive any tip paid above the base fee.
    address public feeRecipient;

    /// @notice Emitted when a user performs an action.
    /// @param user The user address.
    /// @param feePaid The base fee paid.
    /// @param tip The tip amount paid.
    /// @param timestamp The time when the action occurred.
    event ActionPerformed(address indexed user, uint256 feePaid, uint256 tip, uint256 timestamp);

    /// @notice Emitted when the base fee is updated at the end of a period.
    /// @param newBaseFee The new base fee after adjustment.
    event BaseFeeUpdated(uint256 newBaseFee);

    /**
     * @notice Constructor sets the initial parameters.
     * @param _initialBaseFee The starting base fee in wei.
     * @param _targetTxCount The target number of transactions per period.
     * @param _periodLength The duration of each period in seconds.
     * @param _feeRecipient The address that receives tips (if nonzero).
     */
    constructor(
        uint256 _initialBaseFee,
        uint256 _targetTxCount,
        uint256 _periodLength,
        address _feeRecipient
    ) Ownable(msg.sender) {
        require(_initialBaseFee > 0, "Initial base fee must be > 0");
        require(_targetTxCount > 0, "Target tx count must be > 0");
        require(_periodLength > 0, "Period length must be > 0");
        // feeRecipient may be zero if the tip should be burned or kept.

        baseFee = _initialBaseFee;
        targetTxCount = _targetTxCount;
        periodLength = _periodLength;
        periodStart = block.timestamp;
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Performs an action that requires payment of a fee.
     * The caller must send at least `baseFee` wei.
     * The fee consists of a dynamic base fee plus an optional tip.
     * After the action, the contract updates its transaction count and adjusts the base fee if the period has ended.
     */
    function performAction() external payable nonReentrant {
        require(msg.value >= baseFee, "Insufficient fee provided");

        // Calculate tip as any amount sent over the baseFee.
        uint256 tip = msg.value - baseFee;
        // Increment the transaction count.
        txCount++;

        // Check if the current period has ended.
        if (block.timestamp >= periodStart + periodLength) {
            // Adjust the base fee:
            // If more transactions than target, increase baseFee by 10% per excess ratio (simplified);
            // If fewer transactions than target, decrease baseFee by 10% per shortfall, not going below 1 wei.
            if (txCount > targetTxCount) {
                // Increase baseFee proportionally; here we simply add 10% of baseFee.
                baseFee = baseFee + (baseFee / 10);
            } else if (txCount < targetTxCount) {
                uint256 decrease = baseFee / 10;
                if (decrease >= baseFee) {
                    baseFee = 1;
                } else {
                    baseFee = baseFee - decrease;
                }
            }
            // Reset period counters.
            periodStart = block.timestamp;
            txCount = 0;
            emit BaseFeeUpdated(baseFee);
        }

        // If a tip is provided and a feeRecipient is set, forward the tip.
        if (tip > 0 && feeRecipient != address(0)) {
            (bool success, ) = payable(feeRecipient).call{value: tip}("");
            require(success, "Tip transfer failed");
        }

        // The base fee remains in the contract (acting like a burn or pool).
        emit ActionPerformed(msg.sender, baseFee, tip, block.timestamp);
    }
}
