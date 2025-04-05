// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FanToken
 * @dev ERC20 Fan Token with a transaction fee on transfers.
 * A portion of every transfer is deducted as a fee and burned.
 */
contract FanToken is ERC20, Ownable {
    // Transaction fee in basis points (e.g., 50 = 0.5%)
    uint256 public transactionFee;
    // Address to receive fee if needed (currently fee is burned)
    address public feeRecipient;

    event TransactionFeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newFeeRecipient);

    /**
     * @dev Constructor initializes the Fan Token.
     * @param initialSupply Total token supply in smallest units.
     * @param _transactionFee Transaction fee in basis points.
     * @param _feeRecipient Address to receive transaction fees.
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
     * @dev Updates the transaction fee. Only the owner can call.
     */
    function setTransactionFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high"); // Cap at 10%
        transactionFee = newFee;
        emit TransactionFeeUpdated(newFee);
    }

    /**
     * @dev Updates the fee recipient. Only the owner can call.
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }

    /**
     * @dev Overrides transfer to deduct fee on every transfer.
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
     * @dev Overrides transferFrom to deduct fee on every transfer.
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
