// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title InstamineSimToken (⚠️ Educational)
/// @notice All tokens are minted instantly to one address at deploy time.
contract InstamineSimToken is ERC20 {
    constructor(address insider) ERC20("InstaToken", "INS") {
        _mint(insider, 1_000_000 * 1e18); // Total supply goes to insider instantly
    }
}
