// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HardCappedToken is ERC20, Ownable {
    uint256 public immutable maxSupply;

    constructor(uint256 _cap) ERC20("HardCapToken", "HCT") Ownable(msg.sender) {
        maxSupply = _cap * 1e18; // cap in full token units
        _mint(msg.sender, 100_000 * 1e18); // initial mint
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Hard cap reached");
        _mint(to, amount);
    }
}
