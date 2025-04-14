// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NewbPausable
/// @notice ERC20 token with pause functionality. The owner can pause or unpause token transfers.
/// This contract inherits from ERC20Pausable and Ownable.
contract NewbPausable is ERC20Pausable, Ownable {
    /// @notice Constructor sets token details and mints initial supply to initialOwner.
    /// @param initialOwner The address that will receive the initial supply.
    constructor(address initialOwner)
        ERC20("Newb Pausable", "NEWB-P")
        Ownable(initialOwner)
    {
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }

    /// @notice Pause token transfers.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause token transfers.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Mint new tokens (only callable by owner).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Override _beforeTokenTransfer to integrate pause logic.
    /// This override is necessary to hook into ERC20Pausable's implementation.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }
}
