// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SafeToken
/// @notice ERC20 token with mint limit and owner-only mint protection
contract SafeToken is ERC20, Ownable {
    uint256 public maxSupply = 1_000_000 * 1e18;

    constructor() ERC20("SafeToken", "SAFE") Ownable(msg.sender) {
        _mint(msg.sender, 100_000 * 1e18); // Initial supply
    }

    /// @notice Only the owner can mint, up to max supply
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }
}
