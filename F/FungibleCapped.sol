// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FungibleCapped is ERC20Capped, Ownable {
    constructor(address initialOwner)
        ERC20("Capped Token", "CAPT")
        ERC20Capped(1_000_000 * 1e18)
        Ownable(initialOwner)
    {
        _mint(initialOwner, 500_000 * 1e18);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
