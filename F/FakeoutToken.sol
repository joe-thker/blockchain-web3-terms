// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title FakeoutToken
 * @dev ERC20 Token with a dynamic fee mechanism and pausable functionality (termed "FakeOut").
 */
contract FakeoutToken is ERC20, Ownable, Pausable {
    // Fee percentage in basis points (100 basis points = 1%)
    uint256 public feePercentage;
    // Address that receives the fee on every transfer
    address public feeRecipient;
    
    event FeeUpdated(uint256 newFeePercentage);
    event FeeRecipientUpdated(address newFeeRecipient);
    event FakeOutTriggered(address indexed triggeredBy);
    event Resumed(address indexed resumedBy);

    /**
     * @dev Constructor that mints the initial supply, sets the fee parameters, and assigns the token details.
     * @param initialSupply Total token supply (in the smallest unit, e.g., wei for tokens).
     * @param _feePercentage Initial fee percentage in basis points.
     * @param _feeRecipient Address that will receive the fees.
     */
    constructor(
        uint256 initialSupply,
        uint256 _feePercentage,
        address _feeRecipient
    ) ERC20("Fakeout Token", "FAKE") Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        _mint(msg.sender, initialSupply);
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
    }
    
    /**
     * @dev Internal function that applies the fee logic on transfers.
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
     * @dev Overrides the public transfer function to include the fee mechanism.
     * Transfers are allowed only when the contract is not paused.
     */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transferWithFee(msg.sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev Overrides the public transferFrom function to include the fee mechanism.
     * Transfers are allowed only when the contract is not paused.
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
     * @dev Allows the owner to update the fee percentage.
     * The fee is capped at 10% (1000 basis points) for security.
     * @param newFeePercentage New fee percentage in basis points.
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
    
    /**
     * @dev "FakeOut" function – the owner can trigger a pause of all token transfers.
     * This can simulate an emergency or market fakeout scenario.
     */
    function fakeOut() external onlyOwner {
        _pause();
        emit FakeOutTriggered(msg.sender);
    }
    
    /**
     * @dev Resume normal operations by unpausing the contract.
     */
    function resume() external onlyOwner {
        _unpause();
        emit Resumed(msg.sender);
    }
}
