// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BasicHostedWallet {
    address public host;

    constructor() {
        host = msg.sender;
    }

    receive() external payable {}

    function withdrawAll() external {
        require(msg.sender == host, "Not host");
        payable(host).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
