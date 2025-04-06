// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Airdrop Loop Inflation Token
/// @notice Each airdrop increases in size based on total supply — a hyperinflation example
contract AirdropInflationToken is ERC20 {
    mapping(address => bool) public claimed;

    constructor() ERC20("AirdropInflate", "AINF") {}

    function airdrop() external {
        require(!claimed[msg.sender], "Already claimed");

        uint256 amount = totalSupply() + 1000 * 1e18; // Increasing emission
        _mint(msg.sender, amount);

        claimed[msg.sender] = true;
    }
}
