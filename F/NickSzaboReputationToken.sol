// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NickSzaboReputationToken
/// @notice An ERC20 token representing reputation related to Nick Szabo's legacy.
contract NickSzaboReputationToken is ERC20, Ownable {
    /// @notice Constructor mints the initial supply to the owner.
    /// @param initialOwner The address to receive the initial supply.
    constructor(address initialOwner)
        ERC20("Nick Szabo Reputation", "NSR")
        Ownable(initialOwner)
    {
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }

    /// @notice Owner can mint more reputation tokens.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Owner can burn tokens from a given address.
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
