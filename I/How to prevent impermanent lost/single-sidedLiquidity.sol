// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SingleSidedVault {
    IERC20 public token;
    mapping(address => uint256) public balances;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
    }

    function withdraw() external {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "Nothing to withdraw");
        balances[msg.sender] = 0;
        token.transfer(msg.sender, bal);
    }
}
