// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HardcodedInstamine is ERC20 {
    constructor(address dev) ERC20("HardInstamine", "HIM") {
        _mint(dev, 1_000_000 * 1e18);
    }
}
