// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Basic On‑Chain Fiat (BUSD)
 * – Immutable fixed supply minted once to deployer.
 */
contract BasicFiat is ERC20 {
    constructor(uint256 initialSupply)
        ERC20("Basic On-Chain Fiat USD", "BUSD")  // ASCII hyphen
    {
        _mint(msg.sender, initialSupply);
    }
}
