// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DenialOfServiceMitigator
/// @notice This contract demonstrates a pull payment pattern that mitigates denial-of-service (DoS) attacks
/// by allowing users to withdraw their funds rather than automatically pushing Ether to them.
/// Users can deposit Ether, which is tracked in a mapping, and later withdraw it securely.
contract DenialOfServiceMitigator is Ownable, ReentrancyGuard {
    // Mapping to track each user's deposited Ether balance.
    mapping(address => uint256) public balances;

    // Events for logging deposits and withdrawals.
    event Deposited(address indexed sender, uint256 amount);
    event Withdrawal(address indexed receiver, uint256 amount);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Internal function to perform deposit logic.
    function _deposit() internal {
        require(msg.value > 0, "Deposit must be > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice External function to deposit Ether.
    function deposit() external payable {
        _deposit();
    }

    /// @notice Allows users to withdraw their deposited Ether.
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");

        // Reset the user's balance before transferring Ether to prevent reentrancy attacks.
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Fallback function to receive Ether. Calls the internal deposit function.
    receive() external payable {
        _deposit();
    }
}
