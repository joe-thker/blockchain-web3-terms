// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FiatToken
 * @dev ERC20 token representing a fiat-backed stablecoin.
 * The owner (custodian) can mint new tokens or burn tokens to adjust the supply.
 */
contract FiatToken is ERC20, Ownable {
    /**
     * @dev Constructor that mints the initial supply to the deployer.
     * @param initialSupply Total initial supply (in smallest units, e.g., wei for 18 decimals).
     */
    constructor(uint256 initialSupply)
        ERC20("Fiat Token", "FIAT")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }
    
    /**
     * @dev Mints new tokens to a specified address.
     * Can only be called by the owner.
     * @param to Address receiving the minted tokens.
     * @param amount Amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /**
     * @dev Burns tokens from the caller's balance.
     * @param amount Amount of tokens to burn.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    /**
     * @dev Burns tokens from a specified account using the caller's allowance.
     * @param account Account from which tokens will be burned.
     * @param amount Amount of tokens to burn.
     */
    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "FiatToken: burn amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
    }
}
