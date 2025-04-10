// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FlatcoinAlgo
 * @dev Algorithmic Flatcoin that expands supply at a fixed rate (simulating CPI)
 */
contract FlatcoinAlgo is ERC20, Ownable {
    uint256 public targetSupply = 1_000_000 ether;
    uint256 public inflationRate = 2; // 2% annual
    uint256 public lastRebaseTime;

    constructor() ERC20("FlatcoinAlgo", "FLATA") Ownable(msg.sender) {
        _mint(msg.sender, targetSupply);
        lastRebaseTime = block.timestamp;
    }

    /**
     * @dev Rebase supply based on fixed inflation rate
     */
    function rebase() external onlyOwner {
        require(block.timestamp >= lastRebaseTime + 30 days, "Rebase allowed monthly");

        uint256 increase = (totalSupply() * inflationRate) / 100;
        _mint(owner(), increase);
        lastRebaseTime = block.timestamp;
    }
}
