// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Dominance
/// @notice A dynamic and optimized ERC20 token called "Dominance." 
/// The contract owner can mint and burn tokens, making the total supply flexible.
/// Adjust or rename as you wish for real-world usage.
contract Dominance is ERC20, Ownable, ReentrancyGuard {
    /// @notice Constructor sets the token name, symbol, and mints an initial supply to the deployer (owner).
    /// @param initialSupply The number of tokens (in smallest units) to initially mint to the owner.
    constructor(uint256 initialSupply)
        ERC20("Dominance", "DOM")
        Ownable(msg.sender)
    {
        // Mint the initial supply to the contract owner (deployer).
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mints new tokens to a specified address, only callable by the owner.
    /// @param to The address receiving the minted tokens.
    /// @param amount The quantity of tokens (in smallest units) to mint.
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Mint amount must be > 0");
        _mint(to, amount);
    }

    /// @notice Burns a specified amount of tokens from a given address, only callable by the owner.
    /// Decreases total supply.
    /// @param from The address from which tokens will be burned.
    /// @param amount The quantity of tokens to burn (in smallest units).
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn amount must be > 0");
        _burn(from, amount);
    }
}
