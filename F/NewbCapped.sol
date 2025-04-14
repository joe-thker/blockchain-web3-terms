// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NewbCapped
/// @notice ERC20 token with a maximum cap on total supply.
contract NewbCapped is ERC20Capped, Ownable {
    /// @notice Constructor sets token details and supply cap.
    /// @param initialOwner The address for token ownership.
    /// @dev The cap is 1,000,000 NEWB (with 18 decimals).
    constructor(address initialOwner) ERC20("Newb Capped", "NEWB-CAP") ERC20Capped(1_000_000 * 10 ** 18) Ownable(initialOwner) {
        // Initial mint can be less than the cap.
        _mint(initialOwner, 500_000 * 10 ** decimals());
    }
    
    /// @notice Mint tokens, respecting the cap (onlyOwner).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
