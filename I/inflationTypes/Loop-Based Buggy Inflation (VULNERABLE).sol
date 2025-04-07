// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropInflationToken is ERC20 {
    constructor() ERC20("BuggyAirdrop", "LOOP") {}

    // ❌ WARNING: No limit, cap, or access control
    function airdrop(address[] calldata recipients) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], 1000 * 1e18);
        }
    }
}
