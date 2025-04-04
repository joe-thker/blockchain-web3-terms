// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Standard ERC20 Governance Token
contract StandardGovToken is ERC20, Ownable {
    constructor() ERC20("StandardGov", "SGOV") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 1e18); // Mint 1 million SGOV to owner
    }

    /// @notice Owner can mint more tokens (optional)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
