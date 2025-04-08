// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YieldInsuranceFund is Ownable {
    IERC20 public token;
    address public yieldSource;
    uint256 public poolBalance;

    constructor(IERC20 _token, address _yieldSource) Ownable(msg.sender) {
        token = _token;
        yieldSource = _yieldSource;
    }

    function harvest(uint256 amount) external onlyOwner {
        token.transferFrom(yieldSource, address(this), amount);
        poolBalance += amount;
    }

    function emergencyPayout(address to, uint256 amount) external onlyOwner {
        require(amount <= poolBalance, "Insufficient funds");
        poolBalance -= amount;
        token.transfer(to, amount);
    }
}
