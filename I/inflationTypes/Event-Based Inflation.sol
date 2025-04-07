// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EventBasedInflationToken is ERC20, Ownable {
    constructor() ERC20("EventInflation", "EVNT") Ownable(msg.sender) {}

    function reward(address user, uint256 actionWeight) external onlyOwner {
        uint256 rewardAmount = actionWeight * 10 * 1e18; // 10 tokens per unit of work
        _mint(user, rewardAmount);
    }
}
