// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EscrowedEther {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    bool public isApproved;

    event Approved(address indexed by);
    event Refunded(address indexed to);

    constructor(address _beneficiary, address _arbiter) payable {
        require(msg.value > 0, "Send ETH");
        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Not arbiter");
        _;
    }

    function approve() external onlyArbiter {
        require(!isApproved, "Already approved");
        isApproved = true;
        (bool sent, ) = beneficiary.call{value: address(this).balance}("");
        require(sent, "Send failed");
        emit Approved(msg.sender);
    }

    function refund() external onlyArbiter {
        require(!isApproved, "Already approved");
        (bool sent, ) = depositor.call{value: address(this).balance}("");
        require(sent, "Refund failed");
        emit Refunded(depositor);
    }
}
