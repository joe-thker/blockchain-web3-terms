// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin's ERC20 and Ownable contracts.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CashToken
/// @notice An ERC20 token representing a digital cash asset. It can be used for everyday transactions and as a stable store of value.
/// The owner can mint additional tokens if needed, and token holders can burn tokens to reduce supply.
contract CashToken is ERC20, Ownable {
    /// @notice Constructor that initializes the token with a name, symbol, and an initial supply.
    /// @param initialSupply The total initial supply of the token, specified in the smallest unit (e.g., wei for tokens with 18 decimals).
    constructor(uint256 initialSupply) ERC20("Cash Token", "CASH") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
    
    /// @notice Allows the owner to mint new tokens to a specified address.
    /// @param to The address that will receive the minted tokens.
    /// @param amount The number of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /// @notice Allows token holders to burn tokens, permanently removing them from circulation.
    /// @param amount The number of tokens to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
