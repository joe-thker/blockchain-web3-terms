// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DisputeResolutionEscrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;

    enum State { Active, Disputed, Resolved }
    State public state;

    bool public isResolved;

    event Deposited(uint256 amount);
    event DisputeRaised(address by);
    event Approved(address by);
    event Refunded(address to);
    event Resolved(State finalState);

    constructor(address _beneficiary, address _arbiter) payable {
        require(msg.value > 0, "Must send ETH");
        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
        state = State.Active;
        emit Deposited(msg.value);
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter");
        _;
    }

    modifier onlyParties() {
        require(msg.sender == depositor || msg.sender == beneficiary, "Not a party");
        _;
    }

    function raiseDispute() external onlyParties {
        require(state == State.Active, "Not disputable");
        state = State.Disputed;
        emit DisputeRaised(msg.sender);
    }

    function approveToBeneficiary() external onlyArbiter {
        require(state == State.Disputed, "No dispute raised");
        require(!isResolved, "Already resolved");
        isResolved = true;
        state = State.Resolved;
        (bool sent, ) = beneficiary.call{value: address(this).balance}("");
        require(sent, "Transfer failed");
        emit Approved(msg.sender);
        emit Resolved(state);
    }

    function refundToDepositor() external onlyArbiter {
        require(state == State.Disputed, "No dispute raised");
        require(!isResolved, "Already resolved");
        isResolved = true;
        state = State.Resolved;
        (bool sent, ) = depositor.call{value: address(this).balance}("");
        require(sent, "Refund failed");
        emit Refunded(depositor);
        emit Resolved(state);
    }
}
