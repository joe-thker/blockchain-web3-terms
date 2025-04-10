// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SyntheticLPToken is ERC20 {
    constructor() ERC20("Synth LP", "SLP") {}

    function mintSynthetic(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burnSynthetic(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
