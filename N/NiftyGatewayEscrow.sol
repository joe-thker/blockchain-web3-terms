// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NiftyGatewayEscrow
 * @notice A dynamic escrow contract that allows buyers to deposit funds,
 *         later releasing them to sellers or canceling the escrow.
 *         This version features an optional fee mechanism that is configurable
 *         by the admin.
 */
contract NiftyGatewayEscrow {
    // Admin address that has permission to modify settings.
    address public escrowAdmin;
    
    // Dynamic fee parameters.
    uint256 public feePercent = 1; // Default fee is 1%
    address public feeReceiver;

    // Unique identifier for each escrow.
    uint256 public escrowCount;

    // Structure to hold escrow details.
    struct Escrow {
        address buyer;
        address seller;
        uint256 amount;
        bool isActive;
        bool isCompleted;
        bool isCancelled;
        uint256 createdAt;
        uint256 updatedAt;
    }

    // Mapping from escrow ID to Escrow details.
    mapping(uint256 => Escrow) public escrows;

    // Events to help with logging and off-chain tracking.
    event EscrowCreated(uint256 escrowId, address buyer, address seller, uint256 amount);
    event EscrowCompleted(uint256 escrowId);
    event EscrowCancelled(uint256 escrowId);
    event FeeUpdated(uint256 newFeePercent);
    event FeeReceiverUpdated(address newFeeReceiver);

    /**
     * @dev Constructor sets the contract deployer as the admin.
     */
    constructor() {
        escrowAdmin = msg.sender;
        escrowCount = 0;
    }

    // Modifier to restrict functions to escrow admin only.
    modifier onlyAdmin() {
        require(msg.sender == escrowAdmin, "Only admin can perform this action");
        _;
    }

    // Modifier to restrict functions to the buyer associated with a given escrow.
    modifier onlyBuyer(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].buyer, "Only buyer can perform this action");
        _;
    }

    // Modifier to restrict functions to the seller associated with a given escrow.
    modifier onlySeller(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].seller, "Only seller can perform this action");
        _;
    }

    /**
     * @notice Creates a new escrow with a specified seller and deposits funds.
     * @param seller The address of the seller.
     */
    function createEscrow(address seller) external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        escrows[escrowCount] = Escrow({
            buyer: msg.sender,
            seller: seller,
            amount: msg.value,
            isActive: true,
            isCompleted: false,
            isCancelled: false,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        emit EscrowCreated(escrowCount, msg.sender, seller, msg.value);
        escrowCount++;
    }

    /**
     * @notice Releases funds from escrow to the seller.
     * @dev Called only by the buyer.
     * @param escrowId The escrow to release funds from.
     */
    function releaseFunds(uint256 escrowId) external onlyBuyer(escrowId) {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.isActive, "Escrow is not active");
        require(!escrow.isCompleted, "Escrow already completed");
        require(!escrow.isCancelled, "Escrow was cancelled");
        
        // Mark escrow as completed.
        escrow.isCompleted = true;
        escrow.isActive = false;
        escrow.updatedAt = block.timestamp;
        
        // Transfer the full amount to the seller.
        (bool success, ) = escrow.seller.call{value: escrow.amount}("");
        require(success, "Transfer failed");

        emit EscrowCompleted(escrowId);
    }

    /**
     * @notice Releases funds from escrow to the seller while applying a dynamic fee.
     * @dev Called by the buyer, calculates fee and routes funds accordingly.
     * @param escrowId The escrow to release funds from.
     */
    function releaseFundsWithFee(uint256 escrowId) external onlyBuyer(escrowId) {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.isActive, "Escrow is not active");
        require(!escrow.isCompleted, "Escrow already completed");
        require(!escrow.isCancelled, "Escrow was cancelled");
        
        // Calculate fee and seller's share.
        uint256 fee = (escrow.amount * feePercent) / 100;
        uint256 sellerAmount = escrow.amount - fee;
        
        // Mark escrow as completed.
        escrow.isCompleted = true;
        escrow.isActive = false;
        escrow.updatedAt = block.timestamp;
        
        // Transfer fee to feeReceiver if set.
        if (fee > 0 && feeReceiver != address(0)) {
            (bool feeSuccess, ) = feeReceiver.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }
        
        // Transfer the remaining amount to the seller.
        (bool success, ) = escrow.seller.call{value: sellerAmount}("");
        require(success, "Seller transfer failed");

        emit EscrowCompleted(escrowId);
    }

    /**
     * @notice Cancels an active escrow.
     * @dev Can be called by buyer, seller, or admin. Refunds funds to buyer.
     * @param escrowId The escrow to cancel.
     */
    function cancelEscrow(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        require(
            msg.sender == escrow.buyer ||
            msg.sender == escrow.seller ||
            msg.sender == escrowAdmin,
            "Not authorized"
        );
        require(escrow.isActive, "Escrow is not active");
        
        // Mark escrow as cancelled.
        escrow.isCancelled = true;
        escrow.isActive = false;
        escrow.updatedAt = block.timestamp;
        
        // Refund funds to the buyer.
        (bool success, ) = escrow.buyer.call{value: escrow.amount}("");
        require(success, "Refund failed");

        emit EscrowCancelled(escrowId);
    }

    /**
     * @notice Updates the fee percentage.
     * @dev Only the admin can update this value.
     * @param newFeePercent The new fee percentage (0-100).
     */
    function updateFeePercent(uint256 newFeePercent) external onlyAdmin {
        require(newFeePercent <= 100, "Invalid fee percent");
        feePercent = newFeePercent;
        emit FeeUpdated(newFeePercent);
    }

    /**
     * @notice Updates the fee receiver address.
     * @dev Only the admin can update the fee receiver.
     * @param newFeeReceiver The new fee receiver address.
     */
    function updateFeeReceiver(address newFeeReceiver) external onlyAdmin {
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(newFeeReceiver);
    }
    
    /**
     * @dev Prevent accidental direct transfers.
     */
    receive() external payable {
        revert("Direct deposits not allowed");
    }
    
    fallback() external payable {
        revert("No function matches");
    }
}
