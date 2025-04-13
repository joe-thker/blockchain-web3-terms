// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FungibleInterest is ERC20, Ownable {
    uint256 public lastUpdated;
    uint256 public interestRatePerSecond = 1e14; // 0.01% daily (~0.000001 per second)

    mapping(address => uint256) public principal;
    mapping(address => uint256) public lastAccrued;

    constructor(address initialOwner) ERC20("Interest Token", "INT") Ownable(initialOwner) {
        _mint(initialOwner, 1_000_000 * 1e18);
        lastUpdated = block.timestamp;
        principal[initialOwner] = balanceOf(initialOwner);
        lastAccrued[initialOwner] = block.timestamp;
    }

    function accrue(address user) public {
        uint256 p = principal[user];
        uint256 secondsElapsed = block.timestamp - lastAccrued[user];
        uint256 interest = (p * interestRatePerSecond * secondsElapsed) / 1e18;
        _mint(user, interest);
        principal[user] = balanceOf(user);
        lastAccrued[user] = block.timestamp;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        accrue(msg.sender);
        accrue(to);
        return super.transfer(to, amount);
    }
}
