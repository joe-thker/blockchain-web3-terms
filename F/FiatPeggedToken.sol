// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FiatPeggedToken
 * @dev ERC20 token representing a fiat-pegged cryptocurrency.
 * The owner (custodian) is responsible for minting new tokens when fiat is deposited,
 * and burning tokens when fiat is withdrawn. This contract does not enforce the peg on-chain;
 * the peg is maintained off-chain by the custodian's fiat reserves.
 */
contract FiatPeggedToken is ERC20, Ownable {
    // Events for minting and burning tokens.
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    /**
     * @dev Constructor that sets the token name, symbol, and mints the initial supply to the deployer.
     * @param initialSupply Total initial supply in the smallest unit (e.g., if using 18 decimals, 1000 tokens = 1000 * 10^18).
     */
    constructor(uint256 initialSupply)
        ERC20("Fiat Pegged Token", "FPT")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Mints new tokens to a specified address.
     * This function should be called by the owner when fiat deposits are received off-chain.
     * @param to The address that will receive the minted tokens.
     * @param amount The number of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    /**
     * @dev Burns tokens from the caller's account.
     * This function should be called when fiat is withdrawn and the on-chain supply must be reduced.
     * @param amount The number of tokens to burn.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }

    /**
     * @dev Burns tokens from a specified account, deducting from the caller's allowance.
     * @param account The address whose tokens will be burned.
     * @param amount The number of tokens to burn.
     */
    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "FiatPeggedToken: burn amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
        emit Burn(account, amount);
    }
}
