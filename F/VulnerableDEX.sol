// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VulnerableDEX {
    ERC20 public token;
    uint256 public tokenReserve = 1000 * 1e18;
    uint256 public ethReserve;

    event Bought(address indexed user, uint256 ethSpent, uint256 tokensReceived);

    constructor(address _token) {
        token = ERC20(_token);
        token.transferFrom(msg.sender, address(this), tokenReserve);
        ethReserve = address(this).balance;
    }

    // Simple swap function (susceptible to front-running)
    function buyToken() external payable {
        require(msg.value > 0, "Send ETH");
        uint256 tokensOut = getPrice(msg.value);
        require(token.balanceOf(address(this)) >= tokensOut, "Not enough tokens");
        token.transfer(msg.sender, tokensOut);
        ethReserve += msg.value;
        tokenReserve -= tokensOut;

        emit Bought(msg.sender, msg.value, tokensOut);
    }

    function getPrice(uint256 ethIn) public view returns (uint256) {
        return (ethIn * tokenReserve) / (ethReserve + ethIn);
    }

    receive() external payable {}
}
