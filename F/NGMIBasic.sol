// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title BasicNGMIToken
/// @notice A standard ERC20 token called "NGMI Token" with symbol "NGMI".
contract BasicNGMIToken is ERC20, Ownable {
    /// @notice Constructor that sets token details and mints an initial supply.
    /// @param initialOwner The address that receives the initial supply and becomes owner.
    constructor(address initialOwner) ERC20("NGMI Token", "NGMI") Ownable(initialOwner) {
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }
    
    /// @notice Mint additional tokens (only owner).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /// @notice Burn tokens from a specified address (only owner).
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
