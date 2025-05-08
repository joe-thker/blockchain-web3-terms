// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title FungibleToken
/// @notice A standard ERC20 fungible token with mint/burn capability by owner
contract FungibleToken is ERC20, Ownable {
    uint8 private immutable _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply,
        address initialOwner
    ) ERC20(name_, symbol_) Ownable(initialOwner) {
        _decimals = decimals_;
        _mint(initialOwner, initialSupply * (10 ** decimals_));
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @notice Mint tokens (onlyOwner)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Burn tokens (onlyOwner)
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
