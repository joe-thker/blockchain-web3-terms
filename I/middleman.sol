// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EscrowNoMiddleman {
    address public buyer;
    address public seller;
    uint256 public amount;
    bool public buyerApproved;
    bool public sellerApproved;

    enum State { AWAITING_PAYMENT, AWAITING_APPROVAL, COMPLETE }
    State public currentState;

    constructor(address _seller) {
        buyer = msg.sender;
        seller = _seller;
        currentState = State.AWAITING_PAYMENT;
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(currentState == State.AWAITING_PAYMENT, "Already funded");
        require(msg.value > 0, "Zero amount");
        amount = msg.value;
        currentState = State.AWAITING_APPROVAL;
    }

    function approve() external {
        require(currentState == State.AWAITING_APPROVAL, "Wrong state");
        if (msg.sender == buyer) {
            buyerApproved = true;
        } else if (msg.sender == seller) {
            sellerApproved = true;
        } else {
            revert("Unauthorized");
        }

        if (buyerApproved && sellerApproved) {
            currentState = State.COMPLETE;
            payable(seller).transfer(amount);
        }
    }

    function cancel() external {
        require(msg.sender == buyer, "Only buyer can cancel");
        require(!buyerApproved || !sellerApproved, "Already approved");
        payable(buyer).transfer(address(this).balance);
        currentState = State.AWAITING_PAYMENT;
        buyerApproved = false;
        sellerApproved = false;
        amount = 0;
    }
}
