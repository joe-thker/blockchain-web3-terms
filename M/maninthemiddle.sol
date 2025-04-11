// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract VulnerableContract {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function safeTransfer(address to, uint256 amount) external {
        require(msg.sender == owner, "Only owner");
        // But no check on source of `amount` → off-chain MitM could inject
        payable(to).transfer(amount); // sends ETH
    }

    receive() external payable {}
}
