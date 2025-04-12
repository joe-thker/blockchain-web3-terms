// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDex {
    function buyToken() external payable;
    function getPrice(uint256 ethIn) external view returns (uint256);
}

contract SimpleSwapFrontRun {
    IDex public dex;
    address public owner;

    constructor(address _dex) {
        dex = IDex(_dex);
        owner = msg.sender;
    }

    function attack() external payable {
        require(msg.sender == owner, "Only owner");
        dex.buyToken{value: msg.value}();
    }

    receive() external payable {}
}
