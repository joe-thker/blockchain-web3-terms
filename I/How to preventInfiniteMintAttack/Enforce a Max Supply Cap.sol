// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MintCappedToken
/// @notice ERC20 token with capped supply and owner-only minting
contract MintCappedToken is ERC20, Ownable {
    uint256 public immutable maxSupply = 1_000_000 * 1e18;

    constructor() ERC20("MintCappedToken", "MCT") Ownable(msg.sender) {
        _mint(msg.sender, 100_000 * 1e18); // Initial mint
    }

    /// @notice Only the owner can mint new tokens, and only within the cap
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }
}
