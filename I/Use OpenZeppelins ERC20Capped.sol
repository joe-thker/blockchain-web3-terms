// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title UltraSafeToken
/// @notice An ERC20 token with a mint cap and owner-only minting protection
contract UltraSafeToken is ERC20Capped, Ownable {
    constructor()
        ERC20("UltraSafe", "ULTRA")
        ERC20Capped(1_000_000 * 1e18)
        Ownable(msg.sender) // ✅ Fix: specify the initial owner
    {
        _mint(msg.sender, 500_000 * 1e18); // Initial supply to deployer
    }

    /// @notice Only the owner can mint new tokens up to the cap
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount); // ERC20Capped enforces the cap internally
    }
}
