// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FeeTiersERC20
 * @dev ERC20 token with fee tiers. A fee is deducted on transfers based on the transfer amount.
 * The fee is sent to a fee recipient, and the net amount is delivered to the recipient.
 */
contract FeeTiersERC20 is ERC20, Ownable {
    // Structure representing a fee tier.
    struct FeeTier {
        uint256 minAmount; // Minimum transfer amount (inclusive) for this tier.
        uint256 maxAmount; // Maximum transfer amount (inclusive); 0 indicates no upper limit.
        uint256 feeBP;     // Fee in basis points (e.g., 50 means 0.5%).
    }

    FeeTier[] public feeTiers;
    // Address that receives the fees.
    address public feeRecipient;

    event FeeTierAdded(uint256 indexed index, uint256 minAmount, uint256 maxAmount, uint256 feeBP);
    event FeeTierUpdated(uint256 indexed index, uint256 minAmount, uint256 maxAmount, uint256 feeBP);
    event FeeTierRemoved(uint256 indexed index);
    event FeeRecipientUpdated(address newFeeRecipient);

    /**
     * @dev Constructor initializes the token, mints initial supply, and sets the fee recipient.
     * @param initialSupply Total token supply in the smallest unit.
     * @param _feeRecipient Address that will receive fees.
     */
    constructor(uint256 initialSupply, address _feeRecipient)
        ERC20("Fee Tiers ERC20 Token", "FTE20")
        Ownable(msg.sender)
    {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
        _mint(msg.sender, initialSupply);
    }

    /// @dev Allows the owner to update the fee recipient.
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    /// @dev Adds a new fee tier.
    function addFeeTier(uint256 minAmount, uint256 maxAmount, uint256 feeBP) external onlyOwner {
        require(feeBP <= 10000, "Fee too high");
        feeTiers.push(FeeTier(minAmount, maxAmount, feeBP));
        emit FeeTierAdded(feeTiers.length - 1, minAmount, maxAmount, feeBP);
    }

    /// @dev Updates an existing fee tier.
    function updateFeeTier(uint256 index, uint256 minAmount, uint256 maxAmount, uint256 feeBP) external onlyOwner {
        require(index < feeTiers.length, "Invalid index");
        require(feeBP <= 10000, "Fee too high");
        feeTiers[index] = FeeTier(minAmount, maxAmount, feeBP);
        emit FeeTierUpdated(index, minAmount, maxAmount, feeBP);
    }

    /// @dev Removes a fee tier.
    function removeFeeTier(uint256 index) external onlyOwner {
        require(index < feeTiers.length, "Invalid index");
        feeTiers[index] = feeTiers[feeTiers.length - 1];
        feeTiers.pop();
        emit FeeTierRemoved(index);
    }

    /// @dev Returns the fee (in token units) for a given transfer amount.
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
     * @dev Overrides transfer to deduct fee based on fee tiers.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = getFeeForAmount(amount);
        uint256 netAmount = amount - fee;
        // First, transfer the fee to feeRecipient.
        super.transfer(feeRecipient, fee);
        // Then, transfer the net amount to the recipient.
        return super.transfer(recipient, netAmount);
    }

    /**
     * @dev Overrides transferFrom to deduct fee based on fee tiers.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = getFeeForAmount(amount);
        uint256 netAmount = amount - fee;
        // Transfer fee from sender to feeRecipient.
        super.transferFrom(sender, feeRecipient, fee);
        // Transfer net amount from sender to recipient.
        return super.transferFrom(sender, recipient, netAmount);
    }
}
