// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ClaimInflationToken is ERC20 {
    mapping(address => uint256) public lastClaim;
    uint256 public cooldown = 1 days;
    uint256 public rewardAmount = 5 * 1e18;

    constructor() ERC20("ClaimInflation", "CLM") {
        _mint(msg.sender, 100_000 * 1e18); // Seed supply to fund faucet
    }

    function claim() external {
        require(block.timestamp - lastClaim[msg.sender] >= cooldown, "Wait before next claim");
        _mint(msg.sender, rewardAmount);
        lastClaim[msg.sender] = block.timestamp;
    }
}
