// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title LAMBO Token – Meme Claim Contract
contract LamboToken is ERC20 {
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10**18;
    mapping(address => bool) public claimed;

    constructor() ERC20("Lambo Token", "LAMBO") {}

    function claimLambo() external {
        require(!claimed[msg.sender], "Already claimed");
        uint256 amount = (block.timestamp % 100) * 10**18; // random meme logic
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply hit");

        _mint(msg.sender, amount);
        claimed[msg.sender] = true;
    }
}
