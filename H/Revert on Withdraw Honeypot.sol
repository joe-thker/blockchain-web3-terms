// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HoneypotWithdraw {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}
