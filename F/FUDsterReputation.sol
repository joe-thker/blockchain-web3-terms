// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FUDsterReputation is ERC20, Ownable {
    mapping(address => uint256) public reputation;

    constructor(address initialOwner) ERC20("FUD Rep", "FREP") Ownable(initialOwner) {
        _mint(initialOwner, 100_000 * 1e18);
        reputation[initialOwner] = 100;
    }

    function reportFUD(address user) external {
        require(user != msg.sender, "No self reports");
        reputation[user] = reputation[user] > 5 ? reputation[user] - 5 : 0;
    }

    function reward(address user) external onlyOwner {
        reputation[user] += 10;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 rep = reputation[msg.sender];
        uint256 burnRate = rep >= 80 ? 0 : (100 - rep) / 10; // max 10% burn
        uint256 burnAmount = (amount * burnRate) / 100;
        uint256 sendAmount = amount - burnAmount;

        _burn(msg.sender, burnAmount);
        return super.transfer(to, sendAmount);
    }
}
