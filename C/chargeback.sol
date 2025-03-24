// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ChargeBackSystem
/// @notice This contract simulates a simple chargeback mechanism for crypto payments.
/// Buyers can send payments to sellers and file disputes within a specified period. The owner (acting as an administrator)
/// can approve chargebacks to refund the buyer.
contract ChargeBackSystem {
    address public owner; // Administrator who can approve chargebacks
    uint256 public disputePeriod = 30 days; // Dispute period within which a buyer can file a dispute

    struct Payment {
        address buyer;
        address seller;
        uint256 amount;
        uint256 timestamp;
        bool disputed;
        bool chargebackApproved;
        bool refunded;
    }

    // Mapping of payment IDs to Payment details.
    mapping(uint256 => Payment) public payments;
    uint256 public nextPaymentId;

    // Events for logging key actions.
    event PaymentSent(uint256 indexed paymentId, address indexed buyer, address indexed seller, uint256 amount, uint256 timestamp);
    event DisputeFiled(uint256 indexed paymentId, address indexed buyer);
    event ChargeBackApproved(uint256 indexed paymentId, address indexed admin);
    event RefundIssued(uint256 indexed paymentId, address indexed buyer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Sends a payment from the buyer to the seller.
    /// @param seller The recipient of the payment.
    /// @return paymentId The unique ID assigned to the payment.
    function sendPayment(address seller) external payable returns (uint256 paymentId) {
        require(msg.value > 0, "Payment must be > 0 Ether");
        paymentId = nextPaymentId;
        payments[paymentId] = Payment({
            buyer: msg.sender,
            seller: seller,
            amount: msg.value,
            timestamp: block.timestamp,
            disputed: false,
            chargebackApproved: false,
            refunded: false
        });
        nextPaymentId++;
        emit PaymentSent(paymentId, msg.sender, seller, msg.value, block.timestamp);
    }

    /// @notice Allows the buyer to file a dispute on a payment within the dispute period.
    /// @param paymentId The ID of the payment to dispute.
    function fileDispute(uint256 paymentId) external {
        Payment storage p = payments[paymentId];
        require(msg.sender == p.buyer, "Only buyer can file a dispute");
        require(block.timestamp <= p.timestamp + disputePeriod, "Dispute period expired");
        require(!p.disputed, "Dispute already filed");
        p.disputed = true;
        emit DisputeFiled(paymentId, msg.sender);
    }

    /// @notice Allows the owner (admin) to approve a chargeback on a disputed payment.
    /// @param paymentId The ID of the payment to reverse.
    function approveChargeBack(uint256 paymentId) external onlyOwner {
        Payment storage p = payments[paymentId];
        require(p.disputed, "Payment not disputed");
        require(!p.chargebackApproved, "Chargeback already approved");
        p.chargebackApproved = true;
        
        // Refund the payment amount to the buyer.
        (bool sent, ) = p.buyer.call{value: p.amount}("");
        require(sent, "Refund transfer failed");
        p.refunded = true;
        
        emit ChargeBackApproved(paymentId, msg.sender);
        emit RefundIssued(paymentId, p.buyer, p.amount);
    }
}
