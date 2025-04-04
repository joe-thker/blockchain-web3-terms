// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Escrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    uint256 public amount;
    bool public isApproved;

    event Deposited(address indexed from, uint256 amount);
    event Approved(address indexed by, uint256 amount);
    event Refunded(address indexed to, uint256 amount);

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call this");
        _;
    }

    modifier notApproved() {
        require(!isApproved, "Already approved");
        _;
    }

    constructor(address _beneficiary, address _arbiter) payable {
        require(msg.value > 0, "Escrow requires some ETH");
        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
        amount = msg.value;
        emit Deposited(depositor, msg.value);
    }

    function approve() external onlyArbiter notApproved {
        isApproved = true;
        (bool sent, ) = beneficiary.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Approved(msg.sender, amount);
    }

    function refund() external {
        require(msg.sender == beneficiary || msg.sender == arbiter, "Not authorized");
        require(!isApproved, "Already approved");
        uint256 refundAmount = address(this).balance;
        (bool sent, ) = depositor.call{value: refundAmount}("");
        require(sent, "Refund failed");
        emit Refunded(depositor, refundAmount);
    }

    receive() external payable {
        revert("Use constructor to deposit ETH");
    }
}
