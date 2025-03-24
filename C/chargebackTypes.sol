// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChargeBackSystemV2 {
    address public owner;
    uint256 public disputePeriod = 30 days; // Time window in which a dispute can be filed

    // Chargeback types: FULL means refund the entire amount; PARTIAL means refund a portion.
    enum ChargeBackType { FULL, PARTIAL }

    // Payment record with details.
    struct Payment {
        address buyer;
        address seller;
        uint256 amount;
        uint256 timestamp;
        bool disputed;
        bool chargebackApproved;
        bool refunded;
    }

    mapping(uint256 => Payment) public payments;
    uint256 public nextPaymentId;

    event PaymentSent(uint256 indexed paymentId, address indexed buyer, address indexed seller, uint256 amount, uint256 timestamp);
    event DisputeFiled(uint256 indexed paymentId, address indexed buyer);
    event ChargeBackApproved(uint256 indexed paymentId, ChargeBackType chargebackType, uint256 refundAmount);
    event RefundIssued(uint256 indexed paymentId, address indexed buyer, uint256 refundAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Buyer sends a payment to a seller.
    /// @param seller The recipient address.
    /// @return paymentId The ID assigned to the payment.
    function sendPayment(address seller) external payable returns (uint256 paymentId) {
        require(msg.value > 0, "Payment must be > 0");
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

    /// @notice Buyer files a dispute on a payment within the allowed dispute period.
    /// @param paymentId The ID of the payment to dispute.
    function fileDispute(uint256 paymentId) external {
        Payment storage p = payments[paymentId];
        require(msg.sender == p.buyer, "Only buyer can file a dispute");
        require(block.timestamp <= p.timestamp + disputePeriod, "Dispute period expired");
        require(!p.disputed, "Dispute already filed");
        p.disputed = true;
        emit DisputeFiled(paymentId, msg.sender);
    }

    /// @notice Owner approves a chargeback for a disputed payment.
    /// @param paymentId The ID of the payment.
    /// @param cbt The type of chargeback (FULL or PARTIAL).
    /// @param refundAmount For partial chargebacks, the amount to refund; ignored for full chargebacks.
    function approveChargeBack(uint256 paymentId, ChargeBackType cbt, uint256 refundAmount) external onlyOwner {
        Payment storage p = payments[paymentId];
        require(p.disputed, "Payment not disputed");
        require(!p.chargebackApproved, "Chargeback already approved");
        p.chargebackApproved = true;
        
        if(cbt == ChargeBackType.FULL) {
            refundAmount = p.amount;
        } else if(cbt == ChargeBackType.PARTIAL) {
            require(refundAmount < p.amount, "Partial refund must be less than full amount");
        }
        
        // Refund the buyer.
        (bool sent, ) = p.buyer.call{value: refundAmount}("");
        require(sent, "Refund transfer failed");
        p.refunded = true;
        
        emit ChargeBackApproved(paymentId, cbt, refundAmount);
        emit RefundIssued(paymentId, p.buyer, refundAmount);
    }
}
