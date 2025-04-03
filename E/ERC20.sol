// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DynamicERC20
/// @notice An ERC20 token that supports dynamic supply adjustments via minting and burning.
/// Only the contract owner can mint or burn tokens, allowing flexible supply management.
contract DynamicERC20 is ERC20, Ownable, ReentrancyGuard {
    /**
     * @notice Constructor initializes the token with a name, symbol, and an initial supply.
     * @param initialSupply The initial token supply (in smallest units) minted to the deployer.
     */
    constructor(uint256 initialSupply)
        ERC20("DynamicERC20", "DYN")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Mints new tokens to a specified address.
     * @dev Only the contract owner can call this function.
     * @param to The address that receives the minted tokens.
     * @param amount The number of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Cannot mint to the zero address");
        require(amount > 0, "Amount must be greater than 0");
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from a specified address.
     * @dev Only the contract owner can call this function.
     * @param from The address from which tokens will be burned.
     * @param amount The number of tokens to burn.
     */
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        _burn(from, amount);
    }
}
