// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ERC7683Token
/// @notice A dynamic and optimized ERC20 token with a fee mechanism.
/// For each transfer, a fee (expressed in basis points) is deducted from the transferred amount and sent to a designated fee recipient.
/// The fee percentage and fee recipient are adjustable by the owner.
contract ERC7683Token is ERC20, Ownable, ReentrancyGuard {
    /// @notice Fee percentage in basis points (parts per 10,000).
    uint256 public feePercentage;
    /// @notice Address that receives the fee.
    address public feeRecipient;

    /// @notice Emitted when the fee percentage is updated.
    event FeePercentageUpdated(uint256 newFeePercentage);
    /// @notice Emitted when the fee recipient is updated.
    event FeeRecipientUpdated(address newFeeRecipient);

    /**
     * @notice Constructor initializes the token with a name, symbol, initial supply, fee percentage, and fee recipient.
     * @param initialSupply The initial token supply (in smallest units) minted to the deployer.
     * @param _feePercentage The initial fee percentage (in basis points).
     * @param _feeRecipient The address to receive the fee.
     */
    constructor(
        uint256 initialSupply,
        uint256 _feePercentage,
        address _feeRecipient
    ) ERC20("ERC7683 Token", "ERC7683") Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_feePercentage < 10000, "Fee percentage too high"); // less than 100%

        _mint(msg.sender, initialSupply);
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Updates the fee percentage.
     * @param newFeePercentage The new fee percentage in basis points.
     */
    function setFeePercentage(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage < 10000, "Fee percentage too high");
        feePercentage = newFeePercentage;
        emit FeePercentageUpdated(newFeePercentage);
    }

    /**
     * @notice Updates the fee recipient address.
     * @param newFeeRecipient The new fee recipient.
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }

    /**
     * @notice Overrides the ERC20 transfer function to include a fee deduction.
     * The fee is calculated as (amount * feePercentage) / 10000.
     * The fee is transferred to feeRecipient and the remaining amount to the recipient.
     * @param to The recipient address.
     * @param amount The total amount to transfer.
     * @return True if the transfer succeeds.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(amount > 0, "Transfer amount must be > 0");
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 amountAfterFee = amount - fee;

        // Deduct fee and transfer fee to feeRecipient.
        _transfer(_msgSender(), feeRecipient, fee);
        // Transfer the remaining amount to the recipient.
        _transfer(_msgSender(), to, amountAfterFee);

        return true;
    }

    /**
     * @notice Overrides the ERC20 transferFrom function to include a fee deduction.
     * The fee is calculated as (amount * feePercentage) / 10000.
     * The fee is transferred to feeRecipient and the remaining amount to the recipient.
     * The allowance is reduced by the total amount.
     * @param from The address from which tokens are transferred.
     * @param to The recipient address.
     * @param amount The total amount to transfer.
     * @return True if the transfer succeeds.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(amount > 0, "Transfer amount must be > 0");
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 amountAfterFee = amount - fee;

        // Transfer fee and amount after fee.
        _transfer(from, feeRecipient, fee);
        _transfer(from, to, amountAfterFee);

        uint256 currentAllowance = allowance(from, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(from, _msgSender(), currentAllowance - amount);

        return true;
    }
}
