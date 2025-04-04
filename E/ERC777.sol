// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DynamicERC777
/// @notice An ERC777 token contract with dynamic supply management.
/// Only the owner can mint or burn tokens. This contract is designed to be dynamic and optimized.
contract DynamicERC777 is ERC777, Ownable, ReentrancyGuard {
    /**
     * @notice Constructor initializes the ERC777 token.
     * @param name_ The name of the token.
     * @param symbol_ The token symbol.
     * @param defaultOperators An array of default operator addresses.
     * @param initialSupply The initial token supply (in smallest units) minted to the deployer.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators,
        uint256 initialSupply
    )
        ERC777(name_, symbol_, defaultOperators)
        Ownable(msg.sender)
    {
        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply, "", "");
        }
    }

    /**
     * @notice Mints new tokens to a specified address.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "DynamicERC777: mint to zero address");
        require(amount > 0, "DynamicERC777: amount must be > 0");
        _mint(to, amount, "", "");
    }

    /**
     * @notice Burns tokens from a specified address.
     * @param from The address from which tokens will be burned.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "DynamicERC777: amount must be > 0");
        _burn(from, amount, "", "");
    }
}
