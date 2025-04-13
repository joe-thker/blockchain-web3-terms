// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract FungiblePermit is ERC20Permit {
    constructor()
        ERC20("Permit Token", "PRMT")
        ERC20Permit("Permit Token")
    {
        _mint(msg.sender, 1_000_000 * 1e18);
    }
}
