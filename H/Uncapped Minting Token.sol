// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UncappedInflationToken is ERC20 {
    address public admin;

    constructor() ERC20("UncappedInflate", "UINF") {
        admin = msg.sender;
        _mint(admin, 1_000 * 1e18);
    }

    function mint(uint256 amount) external {
        require(msg.sender == admin, "Only admin");
        _mint(admin, amount); // No cap!
    }
}
