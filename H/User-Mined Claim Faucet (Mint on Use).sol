// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title ClaimInflationToken
/// @notice Hyperinflation via user-claim faucet
contract ClaimInflationToken is ERC20 {
    mapping(address => uint256) public lastClaim;

    constructor() ERC20("ClaimInflate", "CINF") {}

    function claim() external {
        require(block.timestamp > lastClaim[msg.sender] + 10, "Claim too soon");

        _mint(msg.sender, 100 * 1e18); // Fixed faucet amount
        lastClaim[msg.sender] = block.timestamp;
    }
}
