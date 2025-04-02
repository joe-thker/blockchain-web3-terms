// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DigitalCurrency
/// @notice A dynamic and optimized ERC20 token, where the contract owner can mint and burn tokens.
/// This design allows a flexible supply while providing standard ERC20 features.
contract DigitalCurrency is ERC20, Ownable, ReentrancyGuard {
    /// @notice Constructor initializes the ERC20 token with a name, symbol, and initial supply.
    /// The deployer becomes the owner via Ownable(msg.sender). The initial supply is minted to the owner.
    /// @param name_ The name of the token.
    /// @param symbol_ The symbol of the token.
    /// @param initialSupply The initial amount of tokens minted to the owner (in smallest units).
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    )
        ERC20(name_, symbol_)
        Ownable(msg.sender)
    {
        // Mint initial supply to the owner’s address.
        _mint(msg.sender, initialSupply);
    }

    /// @notice The owner can mint new tokens to a specified address.
    /// @param to The address to receive the newly minted tokens.
    /// @param amount The amount of tokens (in smallest units) to mint.
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Mint to the zero address");
        require(amount > 0, "Mint amount must be > 0");
        _mint(to, amount);
    }

    /// @notice The owner can burn tokens from a specified address.
    /// Typically used to reduce supply. 
    /// @param from The address whose tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn amount must be > 0");
        _burn(from, amount);
    }
}
