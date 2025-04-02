// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Dildo
/// @notice A dynamic, optimized ERC20 token contract named "Dildo." 
/// The contract owner can mint and burn tokens, making supply flexible. 
/// Feel free to rename or adapt this code for real-world use.
contract Dildo is ERC20, Ownable, ReentrancyGuard {
    /// @notice Constructor sets the token name and symbol, 
    /// mints an initial supply to the deployer, and establishes them as the owner.
    /// @param initialSupply The initial supply minted (in smallest units).
    constructor(uint256 initialSupply)
        ERC20("Dildo", "DLDO")
        Ownable(msg.sender)
    {
        // Mint the initial supply to the contract owner (deployer).
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mints new tokens to a specified address, only callable by the contract owner.
    /// @param to The address receiving the minted tokens.
    /// @param amount The amount of tokens to mint (in smallest units).
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Mint amount must be > 0");
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address, only callable by the contract owner.
    /// This decreases total supply.
    /// @param from The address whose tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn amount must be > 0");
        _burn(from, amount);
    }
}
