// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Basic On‑Ledger Currency (BOLC)
 * --------------------------------
 * Fixed total supply minted once to deployer.
 *
 * NOTE: The token name now uses an ASCII hyphen (-) instead of a
 *       Unicode en‑dash, eliminating the Solidity parser error.
 */
contract BasicOLC is ERC20 {
    constructor(uint256 initialSupply)
        ERC20("Basic On-Ledger Currency", "BOLC") // ASCII hyphen ← fixed
    {
        _mint(msg.sender, initialSupply);
    }
}
