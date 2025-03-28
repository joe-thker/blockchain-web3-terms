// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice ConsumerCrypto implements an escrow system for consumer–merchant transactions.
/// Approved merchants can be registered by the owner, and consumers can initiate purchases by sending Ether to an approved merchant.
/// The funds remain in escrow until the consumer confirms delivery (or disputes the purchase).
contract ConsumerCrypto is Ownable, ReentrancyGuard {
    /// @notice PurchaseStatus tracks the state of a purchase.
    enum PurchaseStatus { Pending, Shipped, Delivered, Disputed, Cancelled, Refunded }
    
    /// @notice Purchase stores details of a consumer purchase.
    struct Purchase {
        uint256 id;
        address payable consumer;
        address payable merchant;
        uint256 amount;
        PurchaseStatus status;
        uint256 timestamp;
    }
    
    uint256 public nextPurchaseId;
    mapping(uint256 => Purchase) public purchases;
    
    // Approved merchants mapping.
    mapping(address => bool) public approvedMerchants;
    
    // --- Events ---
    event MerchantRegistered(address indexed merchant);
    event MerchantRemoved(address indexed merchant);
    event PurchaseInitiated(uint256 indexed purchaseId, address indexed consumer, address indexed merchant, uint256 amount);
    event PurchaseShipped(uint256 indexed purchaseId);
    event PurchaseDelivered(uint256 indexed purchaseId);
    event PurchaseDisputed(uint256 indexed purchaseId);
    event PurchaseCancelled(uint256 indexed purchaseId);
    event PurchaseRefunded(uint256 indexed purchaseId);
    event DisputeResolved(uint256 indexed purchaseId, bool refunded);
    
    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // No additional initialization needed.
    }
    
    /// @notice Registers a merchant. Only the owner can call this.
    /// @param merchant The address of the merchant to register.
    function registerMerchant(address merchant) external onlyOwner {
        require(merchant != address(0), "Invalid address");
        require(!approvedMerchants[merchant], "Merchant already registered");
        approvedMerchants[merchant] = true;
        emit MerchantRegistered(merchant);
    }
    
    /// @notice Removes a merchant. Only the owner can call this.
    /// @param merchant The address of the merchant to remove.
    function removeMerchant(address merchant) external onlyOwner {
        require(approvedMerchants[merchant], "Not a registered merchant");
        approvedMerchants[merchant] = false;
        emit MerchantRemoved(merchant);
    }
    
    /// @notice Consumer initiates a purchase by sending Ether to an approved merchant.
    /// @param merchant The address of the approved merchant.
    function initiatePurchase(address payable merchant) external payable nonReentrant {
        require(approvedMerchants[merchant], "Merchant not approved");
        require(msg.value > 0, "Must send Ether");
        
        uint256 purchaseId = nextPurchaseId;
        nextPurchaseId++;
        
        purchases[purchaseId] = Purchase({
            id: purchaseId,
            consumer: payable(msg.sender),
            merchant: merchant,
            amount: msg.value,
            status: PurchaseStatus.Pending,
            timestamp: block.timestamp
        });
        
        emit PurchaseInitiated(purchaseId, msg.sender, merchant, msg.value);
    }
    
    /// @notice Merchant marks a purchase as shipped.
    /// @param purchaseId The ID of the purchase.
    function markShipped(uint256 purchaseId) external nonReentrant {
        Purchase storage p = purchases[purchaseId];
        require(p.id == purchaseId, "Purchase not found");
        require(p.merchant == msg.sender, "Only merchant can mark shipped");
        require(p.status == PurchaseStatus.Pending, "Purchase not pending");
        
        p.status = PurchaseStatus.Shipped;
        emit PurchaseShipped(purchaseId);
    }
    
    /// @notice Consumer confirms delivery, releasing funds to the merchant.
    /// @param purchaseId The ID of the purchase.
    function confirmDelivery(uint256 purchaseId) external nonReentrant {
        Purchase storage p = purchases[purchaseId];
        require(p.id == purchaseId, "Purchase not found");
        require(p.consumer == msg.sender, "Only consumer can confirm delivery");
        require(p.status == PurchaseStatus.Shipped, "Purchase not shipped");
        
        p.status = PurchaseStatus.Delivered;
        (bool success, ) = p.merchant.call{value: p.amount}("");
        require(success, "Transfer failed");
        emit PurchaseDelivered(purchaseId);
    }
    
    /// @notice Consumer disputes a purchase.
    /// @param purchaseId The ID of the purchase.
    function disputePurchase(uint256 purchaseId) external nonReentrant {
        Purchase storage p = purchases[purchaseId];
        require(p.id == purchaseId, "Purchase not found");
        require(p.consumer == msg.sender, "Only consumer can dispute");
        require(p.status == PurchaseStatus.Pending || p.status == PurchaseStatus.Shipped, "Cannot dispute at this stage");
        
        p.status = PurchaseStatus.Disputed;
        emit PurchaseDisputed(purchaseId);
    }
    
    /// @notice Owner resolves a dispute. If refund is true, funds are returned to the consumer;
    /// otherwise, funds are released to the merchant.
    /// @param purchaseId The ID of the disputed purchase.
    /// @param refund True to refund the consumer, false to release funds to the merchant.
    function resolveDispute(uint256 purchaseId, bool refund) external onlyOwner nonReentrant {
        Purchase storage p = purchases[purchaseId];
        require(p.id == purchaseId, "Purchase not found");
        require(p.status == PurchaseStatus.Disputed, "Purchase is not disputed");
        
        if (refund) {
            p.status = PurchaseStatus.Refunded;
            (bool success, ) = p.consumer.call{value: p.amount}("");
            require(success, "Refund failed");
            emit PurchaseRefunded(purchaseId);
        } else {
            p.status = PurchaseStatus.Delivered;
            (bool success, ) = p.merchant.call{value: p.amount}("");
            require(success, "Transfer to merchant failed");
        }
        emit DisputeResolved(purchaseId, refund);
    }
    
    /// @notice Consumer cancels a purchase if the merchant hasn't shipped within 3 days.
    /// @param purchaseId The ID of the purchase.
    function cancelPurchase(uint256 purchaseId) external nonReentrant {
        Purchase storage p = purchases[purchaseId];
        require(p.id == purchaseId, "Purchase not found");
        require(p.consumer == msg.sender, "Only consumer can cancel");
        require(p.status == PurchaseStatus.Pending, "Cannot cancel at this stage");
        require(block.timestamp >= p.timestamp + 3 days, "Cancellation period not reached");
        
        p.status = PurchaseStatus.Cancelled;
        (bool success, ) = p.consumer.call{value: p.amount}("");
        require(success, "Refund failed");
        emit PurchaseCancelled(purchaseId);
    }
    
    // Fallback function to receive Ether.
    receive() external payable {}
}
