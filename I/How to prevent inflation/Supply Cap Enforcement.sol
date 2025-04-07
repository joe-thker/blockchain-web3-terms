// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CappedToken is ERC20Capped, Ownable {
    constructor()
        ERC20("CappedToken", "CAP")
        ERC20Capped(1_000_000 * 1e18)
        Ownable(msg.sender)
    {
        _mint(msg.sender, 100_000 * 1e18);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount); // Cap enforced internally
    }
}
