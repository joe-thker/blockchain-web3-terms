// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FeeTiersToken
 * @dev ERC20 token with fee tiers. When a transfer is made, a fee is calculated based on
 * the transfer amount and pre-defined fee tiers. That fee is transferred to a fee recipient,
 * and the remainder is sent to the recipient.
 */
contract FeeTiersToken is ERC20, Ownable {
    // Structure to define a fee tier.
    struct FeeTier {
        uint256 minAmount; // Minimum transfer amount (inclusive) for this tier.
        uint256 maxAmount; // Maximum transfer amount (inclusive). Use 0 for no upper limit.
        uint256 feeBP;     // Fee in basis points (10000 BP = 100%).
    }

    FeeTier[] public feeTiers;
    // Address that receives the fees.
    address public feeRecipient;

    event FeeTierAdded(uint256 indexed index, uint256 minAmount, uint256 maxAmount, uint256 feeBP);
    event FeeTierUpdated(uint256 indexed index, uint256 minAmount, uint256 maxAmount, uint256 feeBP);
    event FeeTierRemoved(uint256 indexed index);
    event FeeRecipientUpdated(address newFeeRecipient);

    /**
     * @dev Constructor initializes the token and sets the fee recipient.
     * @param initialSupply Total token supply in the smallest unit.
     * @param _feeRecipient Address that will receive fees.
     */
    constructor(uint256 initialSupply, address _feeRecipient)
        ERC20("Fee Tiers Token", "FTT")
        Ownable(msg.sender)
    {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Updates the fee recipient.
     * @param newRecipient The new fee recipient address.
     */
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    /**
     * @dev Adds a new fee tier.
     * @param minAmount Minimum transfer amount (inclusive) for this tier.
     * @param maxAmount Maximum transfer amount (inclusive); use 0 for no upper limit.
     * @param feeBP Fee in basis points for transfers in this tier.
     */
    function addFeeTier(uint256 minAmount, uint256 maxAmount, uint256 feeBP) external onlyOwner {
        require(feeBP <= 10000, "Fee too high");
        feeTiers.push(FeeTier({minAmount: minAmount, maxAmount: maxAmount, feeBP: feeBP}));
        emit FeeTierAdded(feeTiers.length - 1, minAmount, maxAmount, feeBP);
    }

    /**
     * @dev Updates an existing fee tier.
     * @param index Index of the fee tier to update.
     * @param minAmount New minimum transfer amount.
     * @param maxAmount New maximum transfer amount (or 0 for no upper limit).
     * @param feeBP New fee in basis points.
     */
    function updateFeeTier(uint256 index, uint256 minAmount, uint256 maxAmount, uint256 feeBP) external onlyOwner {
        require(index < feeTiers.length, "Invalid index");
        require(feeBP <= 10000, "Fee too high");
        feeTiers[index] = FeeTier({minAmount: minAmount, maxAmount: maxAmount, feeBP: feeBP});
        emit FeeTierUpdated(index, minAmount, maxAmount, feeBP);
    }

    /**
     * @dev Removes a fee tier.
     * @param index Index of the fee tier to remove.
     */
    function removeFeeTier(uint256 index) external onlyOwner {
        require(index < feeTiers.length, "Invalid index");
        feeTiers[index] = feeTiers[feeTiers.length - 1];
        feeTiers.pop();
        emit FeeTierRemoved(index);
    }

    /**
     * @dev Returns the fee for a given transfer amount.
     * If no tier matches, returns 0.
     * @param amount The transfer amount.
     */
    function getFeeForAmount(uint256 amount) public view returns (uint256 fee) {
        for (uint256 i = 0; i < feeTiers.length; i++) {
            FeeTier memory tier = feeTiers[i];
            if (amount >= tier.minAmount && (tier.maxAmount == 0 || amount <= tier.maxAmount)) {
                return (amount * tier.feeBP) / 10000;
            }
        }
        return 0;
    }

    /**
     * @dev Overrides the public transfer function to apply fee tiers.
     * Instead of overriding the internal _transfer (which is non-virtual), we implement
     * fee deduction here.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = getFeeForAmount(amount);
        uint256 netAmount = amount - fee;
        // Transfer fee to feeRecipient.
        _transfer(_msgSender(), feeRecipient, fee);
        // Transfer net amount to recipient.
        _transfer(_msgSender(), recipient, netAmount);
        return true;
    }

    /**
     * @dev Overrides the public transferFrom function to apply fee tiers.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = getFeeForAmount(amount);
        uint256 netAmount = amount - fee;
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        _transfer(sender, feeRecipient, fee);
        _transfer(sender, recipient, netAmount);
        return true;
    }
}
