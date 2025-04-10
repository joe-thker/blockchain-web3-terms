// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DualAssetLPToken is ERC20 {
    address public tokenA;
    address public tokenB;

    constructor(address _a, address _b) ERC20("Pair LP", "PLP") {
        tokenA = _a;
        tokenB = _b;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
