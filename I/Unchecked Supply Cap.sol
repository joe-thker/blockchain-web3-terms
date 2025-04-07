// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MintAttackNoCap is ERC20 {
    constructor() ERC20("UncappedToken", "UNCAP") {
        _mint(msg.sender, 100_000 * 1e18);
    }

    // ❌ No cap check, no owner restriction — inflation risk
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
