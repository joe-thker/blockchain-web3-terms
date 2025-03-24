// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin's ERC20 and Ownable implementations.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Cash Token
/// @notice An ERC20 token that represents digital cash, enabling everyday transactions and liquidity in crypto markets.
contract Cash is ERC20, Ownable {
    /// @notice Constructor that initializes the token with a name, symbol, and an initial supply.
    /// @param initialSupply The total initial supply of the token, expressed in the smallest unit (e.g., wei for tokens with 18 decimals).
    constructor(uint256 initialSupply) ERC20("Cash", "CASH") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
    
    /// @notice Allows the owner to mint additional tokens.
    /// @param to The address to receive the minted tokens.
    /// @param amount The number of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /// @notice Allows token holders to burn tokens from their balance, reducing the total supply.
    /// @param amount The number of tokens to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
