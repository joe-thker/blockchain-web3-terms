// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SingleApprovalEscrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    bool public isApproved;

    event Deposited(uint256 amount);
    event Approved(address indexed by);
    event Refunded(address indexed to);

    constructor(address _beneficiary, address _arbiter) payable {
        require(msg.value > 0, "Must send ETH");
        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
        emit Deposited(msg.value);
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter");
        _;
    }

    function approve() external onlyArbiter {
        require(!isApproved, "Already approved");
        isApproved = true;
        (bool sent, ) = beneficiary.call{value: address(this).balance}("");
        require(sent, "Transfer failed");
        emit Approved(msg.sender);
    }

    function refund() external {
        require(!isApproved, "Already approved");
        require(msg.sender == arbiter || msg.sender == beneficiary, "Not allowed");
        (bool sent, ) = depositor.call{value: address(this).balance}("");
        require(sent, "Refund failed");
        emit Refunded(depositor);
    }
}
