// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin's ERC20 and Ownable contracts.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CircleToken
/// @notice An ERC20 token representing the "Circle" asset. It can be used as a medium of exchange,
/// a store of value, or for various DeFi applications. The owner can mint new tokens, and token holders can burn tokens.
contract CircleToken is ERC20, Ownable {
    /// @notice Constructor initializes the token with a name, symbol, and an initial supply minted to the deployer.
    /// @param initialSupply The total initial supply of tokens (in the smallest unit, e.g., wei for tokens with 18 decimals).
    constructor(uint256 initialSupply) ERC20("Circle", "CIRC") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
    
    /// @notice Allows the owner to mint additional tokens to a specified address.
    /// @param to The address that will receive the minted tokens.
    /// @param amount The number of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /// @notice Allows token holders to burn tokens, permanently reducing the total supply.
    /// @param amount The number of tokens to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
