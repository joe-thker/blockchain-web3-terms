// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NGMICappedToken
/// @notice An ERC20 token called "NGMI Capped" (symbol: NGMI-C) with a maximum supply cap.
contract NGMICappedToken is ERC20Capped, Ownable {
    /// @notice Constructor sets the token details and caps the maximum supply.
    /// @param initialOwner The address to receive the initial mint.
    /// @dev Cap is set to 1,000,000 tokens (with 18 decimals) and an initial supply of 500,000 tokens is minted.
    constructor(address initialOwner)
        ERC20("NGMI Capped", "NGMI-C")
        ERC20Capped(1_000_000 * 10 ** 18)
        Ownable(initialOwner)
    {
        _mint(initialOwner, 500_000 * 10 ** decimals());
    }
    
    /// @notice Mint function respecting the cap (only owner).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
