// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TimedMintToken is ERC20, Ownable {
    uint256 public lastMint;
    uint256 public mintCooldown = 1 days;

    constructor() ERC20("TimedMint", "TMT") Ownable(msg.sender) {
        lastMint = block.timestamp;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(block.timestamp >= lastMint + mintCooldown, "Mint cooldown active");
        _mint(to, amount);
        lastMint = block.timestamp;
    }
}
