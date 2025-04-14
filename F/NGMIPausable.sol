// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NGMIPausableToken
/// @notice ERC20 token "NGMI Pausable" that supports emergency pause functionality.
/// The owner can pause/unpause transfers and mint new tokens.
contract NGMIPausableToken is ERC20Pausable, Ownable {
    constructor(address initialOwner)
        ERC20("NGMI Pausable", "NGMI-P")
        Ownable(initialOwner)
    {
        // Mint 1,000,000 tokens (assuming 18 decimals) to the initial owner.
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }

    /// @notice Allows the owner to pause token transfers.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Allows the owner to unpause token transfers.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Mint new tokens, callable only by the owner.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Override the _beforeTokenTransfer hook to integrate pause functionality.
    /// No explicit base contracts are listed in the override clause.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }
}
