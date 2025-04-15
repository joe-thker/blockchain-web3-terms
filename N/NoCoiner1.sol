// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NoCoiner1
 * @notice ERC20 token with a dynamic fee mechanism.
 *         This version avoids overriding _transfer since it is not virtual in your OpenZeppelin version.
 *         Instead, it implements fee logic within transfer and transferFrom.
 */
contract NoCoiner1 is ERC20, Ownable {
    // Fee percentage (e.g., a value of 2 means 2% fee on transfers).
    uint256 public feePercent;
    // Address that receives the fee.
    address public feeReceiver;

    /**
     * @dev Constructor initializes the token with a name, symbol, initial supply, fee percent, and fee receiver.
     * @param initialSupply Total tokens minted to the deployer.
     * @param _feePercent Initial fee percent (0-100) to be applied on transfers.
     * @param _feeReceiver Address that will receive the fee.
     */
    constructor(
        uint256 initialSupply,
        uint256 _feePercent,
        address _feeReceiver
    )
        ERC20("NoCoiner1", "NOC1")
        Ownable(msg.sender)
    {
        require(_feeReceiver != address(0), "Invalid fee receiver");
        require(_feePercent <= 100, "Fee percent must be between 0 and 100");

        feePercent = _feePercent;
        feeReceiver = _feeReceiver;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Updates the fee percentage and fee receiver.
     * @param newFeePercent New fee percentage (0-100).
     * @param newFeeReceiver New address to receive fees.
     */
    function updateFee(uint256 newFeePercent, address newFeeReceiver) external onlyOwner {
        require(newFeeReceiver != address(0), "Invalid fee receiver");
        require(newFeePercent <= 100, "Fee percent must be between 0 and 100");

        feePercent = newFeePercent;
        feeReceiver = newFeeReceiver;
    }

    /**
     * @notice Overridden transfer function that applies fee logic.
     *         If the sender is not the owner and feePercent is nonzero, a fee is deducted.
     * @param recipient The address to receive tokens.
     * @param amount The total amount intended for transfer.
     * @return success True if the transfer succeeded.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (msg.sender != owner() && feePercent > 0) {
            uint256 fee = (amount * feePercent) / 100;
            uint256 netAmount = amount - fee;

            // Transfer fee to feeReceiver.
            bool feeSuccess = super.transfer(feeReceiver, fee);
            require(feeSuccess, "Fee transfer failed");
            // Then transfer the net amount to the recipient.
            return super.transfer(recipient, netAmount);
        } else {
            return super.transfer(recipient, amount);
        }
    }

    /**
     * @notice Overridden transferFrom function that applies fee logic.
     *         Non-owner senders incur a fee that is taken from the total amount.
     * @param sender The address sending tokens.
     * @param recipient The address receiving tokens.
     * @param amount The total amount intended for transfer.
     * @return success True if the transfer succeeded.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (sender != owner() && feePercent > 0) {
            uint256 fee = (amount * feePercent) / 100;
            uint256 netAmount = amount - fee;

            // Deduct the entire amount from sender's allowance.
            _spendAllowance(sender, _msgSender(), amount);
            // Transfer fee and net amount in separate calls.
            _transfer(sender, feeReceiver, fee);
            _transfer(sender, recipient, netAmount);
            return true;
        } else {
            return super.transferFrom(sender, recipient, amount);
        }
    }
}
