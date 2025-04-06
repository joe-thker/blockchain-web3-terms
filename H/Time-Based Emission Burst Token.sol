// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title TimeBasedBurstToken
/// @notice Mints exponentially increasing token amounts based on elapsed time
contract TimeBasedBurstToken is ERC20 {
    uint256 public lastMintTime;

    constructor() ERC20("BurstInflate", "TINF") {
        lastMintTime = block.timestamp;
    }

    function mint() external {
        uint256 elapsed = block.timestamp - lastMintTime;
        require(elapsed > 0, "Wait before minting again");

        uint256 amount = (elapsed ** 2) * 1e15; // Quadratic inflation growth
        _mint(msg.sender, amount);
        lastMintTime = block.timestamp;
    }
}
