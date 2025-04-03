// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FairAIToken
 * @dev ERC20 Token with a dynamic fee mechanism applied in public transfer functions.
 */
contract FairAIToken is ERC20, Ownable {
    // Fee percentage in basis points (100 basis points = 1%)
    uint256 public feePercentage;
    // Address that receives the fee on every transfer
    address public feeRecipient;
    
    event FeeUpdated(uint256 newFeePercentage);
    event FeeRecipientUpdated(address newFeeRecipient);

    /**
     * @dev Constructor that mints the initial supply and sets the fee parameters.
     * @param initialSupply Total token supply (in the smallest unit, e.g. wei for tokens).
     * @param _feePercentage Initial fee percentage in basis points.
     * @param _feeRecipient Address that will receive the transfer fees.
     */
    constructor(
        uint256 initialSupply,
        uint256 _feePercentage,
        address _feeRecipient
    ) ERC20("Fair AI Token", "FAIT") Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        _mint(msg.sender, initialSupply);
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
    }
    
    /**
     * @dev Internal function that applies the fee logic and performs the transfers.
     * @param sender Address sending the tokens.
     * @param recipient Address receiving the tokens.
     * @param amount Total amount of tokens to transfer (before fee deduction).
     */
    function _transferWithFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (feePercentage > 0 && feeRecipient != address(0)) {
            uint256 fee = (amount * feePercentage) / 10000;
            uint256 amountAfterFee = amount - fee;
            // Transfer fee to feeRecipient
            super._transfer(sender, feeRecipient, fee);
            // Transfer remaining tokens to recipient
            super._transfer(sender, recipient, amountAfterFee);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
    
    /**
     * @dev Overrides the public transfer function to include fee mechanism.
     * @param recipient Address receiving the tokens.
     * @param amount Total amount of tokens to transfer (before fee deduction).
     * @return success Returns true on successful transfer.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferWithFee(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Overrides the public transferFrom function to include fee mechanism.
     * Also reduces the caller's allowance accordingly.
     * @param sender Address sending the tokens.
     * @param recipient Address receiving the tokens.
     * @param amount Total amount of tokens to transfer (before fee deduction).
     * @return success Returns true on successful transfer.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        _transferWithFee(sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev Allows the owner to update the fee percentage.
     * @param newFeePercentage New fee percentage in basis points.
     * Note: The fee is capped at 10% (1000 basis points) for security.
     */
    function updateFeePercentage(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 1000, "Fee too high");
        feePercentage = newFeePercentage;
        emit FeeUpdated(newFeePercentage);
    }
    
    /**
     * @dev Allows the owner to update the fee recipient address.
     * @param newFeeRecipient New fee recipient address.
     */
    function updateFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }
}
