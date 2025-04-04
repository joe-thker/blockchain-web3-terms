// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Delegated Governance Token using ERC20Votes
contract DelegatedGovToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    constructor()
        ERC20("DelegatedGov", "DGOV")
        ERC20Permit("DelegatedGov") // Also sets EIP712 name
        Ownable(msg.sender)
    {
        _mint(msg.sender, 1_000_000 * 1e18); // Initial supply
    }

    // The following overrides are required by Solidity due to multiple inheritance.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address from, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(from, amount);
    }
}
