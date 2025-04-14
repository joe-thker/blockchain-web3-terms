// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @title NewbPermit
/// @notice ERC20 token with permit functionality (gasless approvals).
contract NewbPermit is ERC20Permit {
    constructor() ERC20("Newb Permit", "NEWB-PMT") ERC20Permit("Newb Permit") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
