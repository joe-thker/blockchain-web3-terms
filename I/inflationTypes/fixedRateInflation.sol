// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FixedInflationToken is ERC20, Ownable {
    uint256 public immutable emissionPerBlock = 10 * 1e18;
    uint256 public lastMintedBlock;

    constructor() ERC20("FixedInflation", "FIXED") Ownable(msg.sender) {
        lastMintedBlock = block.number;
    }

    function mint() external onlyOwner {
        uint256 blocksPassed = block.number - lastMintedBlock;
        require(blocksPassed > 0, "Already minted this block");
        uint256 amount = blocksPassed * emissionPerBlock;
        _mint(msg.sender, amount);
        lastMintedBlock = block.number;
    }
}
