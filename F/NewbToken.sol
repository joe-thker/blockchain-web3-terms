// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NewbToken
/// @notice A standard ERC20 token named "Newb Token" with symbol "NEWB".
contract NewbToken is ERC20, Ownable {
    /// @notice Constructor that sets token details and mints an initial supply.
    /// @param initialOwner The address of the token owner (will receive the initial supply).
    constructor(address initialOwner) ERC20("Newb Token", "NEWB") Ownable(initialOwner) {
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }
    
    /// @notice Mint additional tokens (onlyOwner).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /// @notice Burn tokens from a given address (onlyOwner).
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
