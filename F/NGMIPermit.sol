// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @title NGMIPermitToken
/// @notice ERC20 token called "NGMI Permit" (symbol: NGMI-PMT) with permit (gasless approvals) functionality.
contract NGMIPermitToken is ERC20Permit {
    constructor()
        ERC20("NGMI Permit", "NGMI-PMT")
        ERC20Permit("NGMI Permit")
    {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
