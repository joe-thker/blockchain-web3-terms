// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title EquityToken
/// @notice Base ERC20 token representing equity with mint and burn functionality.
/// This contract is intended to be inherited by specific equity token types.
contract EquityToken is ERC20, Ownable, ReentrancyGuard {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        Ownable(msg.sender)
    {}

    /// @notice Mints tokens to a specified address.
    /// @param to The address receiving minted tokens.
    /// @param amount The amount to mint.
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Mint amount must be > 0");
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address.
    /// @param from The address from which tokens are burned.
    /// @param amount The amount to burn.
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Burn amount must be > 0");
        _burn(from, amount);
    }
}

/// @title CommonEquity
/// @notice A common equity token representing standard equity rights.
contract CommonEquity is EquityToken {
    /// @notice Constructor mints the initial supply of common equity tokens to the deployer.
    /// @param initialSupply The initial supply, in smallest token units.
    constructor(uint256 initialSupply) EquityToken("Common Equity Token", "CET") {
        _mint(msg.sender, initialSupply);
    }
}

/// @title PreferredEquity
/// @notice A preferred equity token representing preferential rights (e.g., dividends).
contract PreferredEquity is EquityToken {
    /// @notice Constructor mints the initial supply of preferred equity tokens to the deployer.
    /// @param initialSupply The initial supply, in smallest token units.
    constructor(uint256 initialSupply) EquityToken("Preferred Equity Token", "PET") {
        _mint(msg.sender, initialSupply);
    }
}

/// @title ConvertibleEquity
/// @notice A convertible equity token that can be converted into another asset.
/// For demonstration purposes, conversion simply burns tokens.
contract ConvertibleEquity is EquityToken {
    /// @notice Constructor mints the initial supply of convertible equity tokens to the deployer.
    /// @param initialSupply The initial supply, in smallest token units.
    constructor(uint256 initialSupply) EquityToken("Convertible Equity Token", "COVT") {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Converts a specified amount of convertible equity.
    /// In this demonstration, conversion simply burns the tokens.
    /// @param amount The amount to convert.
    function convert(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be > 0");
        _burn(msg.sender, amount);
        // In a real implementation, conversion logic (e.g. minting another token) would be added here.
    }
}
