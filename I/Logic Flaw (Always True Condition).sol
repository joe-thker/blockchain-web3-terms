// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MintAttackLogicBug is ERC20 {
    constructor() ERC20("BuggyToken", "BUG") {}

    function mintIfAllowed(address to, uint256 amount) external {
        // ❌ Always true: condition is logically broken
        if (to != address(0) || to == address(0)) {
            _mint(to, amount);
        }
    }
}
