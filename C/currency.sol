// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CurrencyToken
/// @notice A dynamic and optimized ERC20 token representing a cryptocurrency.
/// The owner can mint new tokens or burn tokens from any account, allowing for flexible supply management.
/// This contract uses OpenZeppelin's well-audited ERC20 and Ownable modules for security and optimization.
contract CurrencyToken is ERC20, Ownable {
    /// @notice Constructor initializes the token with a name, symbol, and initial supply.
    /// @param name_ The name of the token.
    /// @param symbol_ The symbol of the token.
    /// @param initialSupply The initial token supply minted to the deployer (in smallest units).
    constructor(
        string memory name_, 
        string memory symbol_, 
        uint256 initialSupply
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mints new tokens to a specified account.
    /// @dev Only the owner can call this function.
    /// @param account The address to receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Cannot mint to zero address");
        _mint(account, amount);
    }

    /// @notice Burns tokens from a specified account.
    /// @dev Only the owner can call this function.
    /// @param account The address from which tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function burn(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Cannot burn from zero address");
        _burn(account, amount);
    }
}
