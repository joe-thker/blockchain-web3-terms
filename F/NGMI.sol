// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NGMI Token
/// @notice A simple ERC20 token for the "NGMI" meme, meaning "Not Gonna Make It."
contract NGMIToken is ERC20, Ownable {
    /// @notice Constructor sets the token name, symbol, and mints an initial supply to the initial owner.
    /// @param initialOwner The address which will own the initial supply and be granted ownership.
    constructor(address initialOwner)
        ERC20("NGMI Token", "NGMI")
        Ownable(initialOwner)
    {
        // Mint an initial supply of 1,000,000 tokens (assumed 18 decimals)
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }
    
    /// @notice Mint additional tokens. Only the owner can call this function.
    /// @param to The address that will receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /// @notice Burn tokens from a specified address. Only the owner can call this function.
    /// @param from The address from which tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
