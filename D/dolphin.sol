// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Dolphin
/// @notice A dynamic and optimized ERC20 token named "Dolphin." The contract owner can mint and burn tokens,
/// making the total supply flexible. Adjust naming or functionality as needed for real-world usage.
contract Dolphin is ERC20, Ownable, ReentrancyGuard {
    /// @notice Constructor sets the token name, symbol, and mints an initial supply to the deployer (owner).
    /// @param initialSupply The initial supply of tokens (in smallest units) minted to the owner.
    constructor(uint256 initialSupply)
        ERC20("Dolphin", "DOL")
        Ownable(msg.sender)
    {
        // Mint initial supply to the contract owner (deployer).
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mints new tokens to a specified address, callable only by the owner.
    /// @param to The address receiving the minted tokens.
    /// @param amount The quantity of tokens to mint (in smallest units).
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Mint amount must be > 0");
        _mint(to, amount);
    }

    /// @notice Burns a specified amount of tokens from a given address, callable only by the owner.
    /// Decreases total supply.
    /// @param from The address from which tokens will be burned.
    /// @param amount The quantity of tokens to burn (in smallest units).
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn amount must be > 0");
        _burn(from, amount);
    }
}
