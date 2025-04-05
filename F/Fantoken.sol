// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FanToken
 * @dev ERC20 Fan Token with a transaction fee on transfers.
 * A portion of every transfer is deducted as a fee, which is burned.
 * Only the owner can update fee parameters.
 */
contract FanToken is ERC20, Ownable {
    // Transaction fee in basis points (e.g., 50 means 0.5%)
    uint256 public transactionFee;
    // Address that receives the transaction fee (if desired, though here we burn the fee)
    address public feeRecipient;

    event TransactionFeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newFeeRecipient);

    /**
     * @dev Constructor that initializes the Fan Token.
     * @param initialSupply Total token supply in the smallest unit.
     * @param _transactionFee Transaction fee in basis points.
     * @param _feeRecipient Address to receive the fee (must be non-zero).
     */
    constructor(
        uint256 initialSupply,
        uint256 _transactionFee,
        address _feeRecipient
    ) ERC20("Fan Token", "FAN") Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        transactionFee = _transactionFee;
        feeRecipient = _feeRecipient;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Allows the owner to update the transaction fee.
     * For example, you might cap it at 10% (1000 basis points).
     */
    function setTransactionFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high");
        transactionFee = newFee;
        emit TransactionFeeUpdated(newFee);
    }

    /**
     * @dev Allows the owner to update the fee recipient.
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }

    /**
     * @dev Overrides the public transfer function to apply the fee mechanism.
     * The sender sends (amount - fee) to the recipient and the fee is burned.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * transactionFee) / 10000;
        uint256 sendAmount = amount - fee;
        bool success = super.transfer(recipient, sendAmount);
        require(success, "Transfer failed");
        _burn(_msgSender(), fee);
        return true;
    }

    /**
     * @dev Overrides the public transferFrom function to apply the fee mechanism.
     * The sender’s tokens are reduced by the fee before the recipient receives the net amount.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * transactionFee) / 10000;
        uint256 sendAmount = amount - fee;
        bool success = super.transferFrom(sender, recipient, sendAmount);
        require(success, "Transfer failed");
        _burn(sender, fee);
        return true;
    }
}
