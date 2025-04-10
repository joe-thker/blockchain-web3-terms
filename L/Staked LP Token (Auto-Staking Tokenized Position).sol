// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakedLPToken is ERC20 {
    constructor() ERC20("Staked LP", "sLP") {}

    function stakeMint(address user, uint256 amount) external {
        _mint(user, amount);
    }

    function unstakeBurn(address user, uint256 amount) external {
        _burn(user, amount);
    }
}
