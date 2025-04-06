// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title BlockInflationToken
/// @notice Mints fixed tokens once per block — hyperinflation risk if abused
contract BlockInflationToken is ERC20 {
    uint256 public lastMintedBlock;
    uint256 public constant blockReward = 10 * 1e18;

    constructor() ERC20("BlockInflate", "BINF") {
        lastMintedBlock = block.number;
    }

    /// @notice Mint 10 tokens if not already minted this block
    function mint() external {
        require(block.number > lastMintedBlock, "Already minted this block");

        _mint(msg.sender, blockReward);
        lastMintedBlock = block.number;
    }
}
