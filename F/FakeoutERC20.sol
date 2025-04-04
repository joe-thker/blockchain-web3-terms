// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title FakeoutERC20
 * @dev ERC20 Token with a dynamic fee mechanism and pausable ("Fakeout") functionality.
 */
contract FakeoutERC20 is ERC20, Ownable, Pausable {
    // Fee percentage in basis points (100 basis points = 1%)
    uint256 public feePercentage;
    // Address that receives the fee on every transfer
    address public feeRecipient;
    
    event FeeUpdated(uint256 newFeePercentage);
    event FeeRecipientUpdated(address newFeeRecipient);
    event FakeOutTriggered(address indexed triggeredBy);
    event Resumed(address indexed resumedBy);

    /**
     * @dev Constructor mints the initial supply and sets fee parameters.
     * @param initialSupply Total token supply (in smallest units).
     * @param _feePercentage Initial fee percentage in basis points.
     * @param _feeRecipient Address to receive the fees.
     */
    constructor(
        uint256 initialSupply,
        uint256 _feePercentage,
        address _feeRecipient
    ) ERC20("Fakeout ERC20 Token", "F20") Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        _mint(msg.sender, initialSupply);
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
    }
    
    /**
     * @dev Internal function that applies the fee logic on transfers.
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
     * @dev Overrides transfer to include fee logic and allow transfers only when not paused.
     */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transferWithFee(msg.sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev Overrides transferFrom to include fee logic and allow transfers only when not paused.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        _transferWithFee(sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev Owner can update the fee percentage (capped at 10%).
     */
    function updateFeePercentage(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 1000, "Fee too high");
        feePercentage = newFeePercentage;
        emit FeeUpdated(newFeePercentage);
    }
    
    /**
     * @dev Owner can update the fee recipient address.
     */
    function updateFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }
    
    /**
     * @dev Owner triggers a "FakeOut" to pause token transfers.
     */
    function fakeOut() external onlyOwner {
        _pause();
        emit FakeOutTriggered(msg.sender);
    }
    
    /**
     * @dev Owner resumes normal operations.
     */
    function resume() external onlyOwner {
        _unpause();
        emit Resumed(msg.sender);
    }
}
