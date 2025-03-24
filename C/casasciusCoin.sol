// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin's ERC20 and Ownable implementations.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CasasciusCoin
/// @notice An ERC20 token that simulates a digital version of Casascius Coin.
/// It allows the owner to mint an initial supply and token holders to burn tokens, simulating physical coin redemption.
contract CasasciusCoin is ERC20, Ownable {
    /// @notice Constructor that sets the token name, symbol, and mints an initial supply to the deployer.
    /// @param initialSupply The total initial supply of the token, in wei (for tokens with 18 decimals).
    constructor(uint256 initialSupply) 
        ERC20("CasasciusCoin", "CASA") 
        Ownable(msg.sender) 
    {
        _mint(msg.sender, initialSupply);
    }
    
    /// @notice Burns a specific amount of tokens from the caller's balance.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
