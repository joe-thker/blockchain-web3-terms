// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NewbToken
/// @notice ERC20 token named "Newb Token" with symbol "NEWB"
contract NewbToken is ERC20, Ownable {
    /// @notice Constructor that sets the token name, symbol, and mints an initial supply to the owner.
    /// @param initialOwner The address that will receive the initial supply and be the owner.
    constructor(address initialOwner)
        ERC20("Newb Token", "NEWB")
        Ownable(initialOwner)
    {
        // Mint an initial supply of 1,000,000 tokens (assuming 18 decimals)
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }
    
    /// @notice Mint additional tokens. Only callable by the owner.
    /// @param to The address to receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /// @notice Burn tokens from a specified address. Only callable by the owner.
    /// @param from The address from which tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
