// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ThrottledMintToken is ERC20, Ownable {
    uint256 public maxDailyMint = 10_000 * 1e18;
    uint256 public mintedToday;
    uint256 public lastReset;

    constructor() ERC20("ThrottledMint", "THR") Ownable(msg.sender) {
        lastReset = block.timestamp;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        if (block.timestamp > lastReset + 1 days) {
            mintedToday = 0;
            lastReset = block.timestamp;
        }

        require(mintedToday + amount <= maxDailyMint, "Daily limit exceeded");
        _mint(to, amount);
        mintedToday += amount;
    }
}
