// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EmergencyReserveFund is Ownable {
    IERC20 public token;
    uint256 public reserves;

    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
    }

    function deposit(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        reserves += amount;
    }

    function payout(address recipient, uint256 amount) external onlyOwner {
        require(amount <= reserves, "Insufficient reserve");
        reserves -= amount;
        token.transfer(recipient, amount);
    }
}
