// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CommunitySafetyFund {
    IERC20 public token;
    mapping(address => uint256) public contributions;
    uint256 public totalContributed;

    constructor(IERC20 _token) {
        token = _token;
    }

    function contribute(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        contributions[msg.sender] += amount;
        totalContributed += amount;
    }

    function refund(address contributor, uint256 amount) external {
        require(contributions[contributor] >= amount, "Too much");
        contributions[contributor] -= amount;
        totalContributed -= amount;
        token.transfer(contributor, amount);
    }

    function payoutLoss(address to, uint256 amount) external {
        require(amount <= totalContributed, "Exceeds fund");
        totalContributed -= amount;
        token.transfer(to, amount);
    }
}
