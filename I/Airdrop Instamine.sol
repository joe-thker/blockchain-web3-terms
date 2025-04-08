// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AirdropInstamine is ERC20, Ownable {
    constructor(address[] memory insiders) ERC20("AirdropInstamine", "AIM") Ownable(msg.sender) {
        uint256 total = 1_000_000 * 1e18;
        uint256 insiderShare = (total * 99) / 100;
        uint256 each = insiderShare / insiders.length;

        for (uint256 i = 0; i < insiders.length; i++) {
            _mint(insiders[i], each);
        }

        _mint(msg.sender, total - insiderShare); // remaining 1% to owner
    }
}
