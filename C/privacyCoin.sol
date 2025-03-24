// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title PrivacyCoin
/// @notice An ERC20 token representing a privacy coin. This example simulates obfuscated transfers.
contract PrivacyCoin is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("PrivacyCoin", "PRIV") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Simulates an obfuscated transfer (for demonstration only).
    /// In a real privacy coin, advanced cryptography would hide transaction details.
    function transferObfuscated(address recipient, uint256 amount) external returns (bool) {
        // For simulation, simply perform a regular transfer.
        return transfer(recipient, amount);
    }
}
