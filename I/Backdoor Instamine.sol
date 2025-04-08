// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BackdoorInstamine is ERC20, Ownable {
    bool public leaked;

    constructor() ERC20("BackdoorInstamine", "BDM") Ownable(msg.sender) {
        _mint(msg.sender, 100_000 * 1e18);
    }

    function leakMint(address to, uint256 amount) external onlyOwner {
        require(!leaked, "Already used");
        leaked = true;
        _mint(to, amount);
    }
}
