// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GovernanceToken - ERC20 token for DAO voting rights
contract GovernanceToken is ERC20, Ownable {
    uint256 public maxSupply = 1_000_000 * 1e18; // 1 million max

    constructor() ERC20("Governance Token", "GOV") Ownable(msg.sender) {
        _mint(msg.sender, 100_000 * 1e18); // initial allocation to deployer
    }

    /// @notice Mint new tokens (e.g., for treasury, community)
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds cap");
        _mint(to, amount);
    }
}
