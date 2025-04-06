// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Honeypot {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    /// @notice Looks public... but there’s a hidden trap
    function withdraw() public {
        require(msg.sender == owner, "You aren't the owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    /// Allows depositing ETH to lure victims
    receive() external payable {}
}
