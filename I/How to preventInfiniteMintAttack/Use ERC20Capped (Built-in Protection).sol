// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SafeCapped
/// @notice A mint-protected ERC20 token using ERC20Capped and Ownable
contract SafeCapped is ERC20Capped, Ownable {
    constructor()
        ERC20("SafeCapped", "SCAP")
        ERC20Capped(1_000_000 * 1e18)
        Ownable(msg.sender) // ✅ Fix: Specify initial owner explicitly
    {
        _mint(msg.sender, 500_000 * 1e18); // Initial supply
    }

    /// @notice Only the owner can mint, and total supply cannot exceed cap
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount); // Cap enforced by ERC20Capped
    }
}
