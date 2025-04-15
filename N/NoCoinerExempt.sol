// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NoCoinerExempt
 * @notice ERC20 token with dynamic fee logic and an exemption list.
 *         Fee logic is embedded in the public transfer and transferFrom functions,
 *         making it compatible with OpenZeppelin versions where _transfer is not virtual.
 */
contract NoCoinerExempt is ERC20, Ownable {
    uint256 public feePercent;
    address public feeReceiver;
    // Mapping to store addresses that are exempt from fees.
    mapping(address => bool) public isExempt;

    /**
     * @dev Constructor initializes token parameters.
     * @param initialSupply The total token supply minted to the deployer.
     * @param _feePercent Fee percentage (0-100) applied to transfers.
     * @param _feeReceiver Address that receives the collected fees.
     */
    constructor(
        uint256 initialSupply,
        uint256 _feePercent,
        address _feeReceiver
    ) ERC20("NoCoinerExempt", "NOCX") Ownable(msg.sender) {
        require(_feeReceiver != address(0), "Invalid fee receiver");
        require(_feePercent <= 100, "Fee percent must be between 0 and 100");

        feePercent = _feePercent;
        feeReceiver = _feeReceiver;
        // Owner is exempt by default.
        isExempt[msg.sender] = true;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Updates fee settings.
     * @param newFeePercent New fee percentage (0-100) for transfers.
     * @param newFeeReceiver New address to receive fees.
     */
    function updateFee(uint256 newFeePercent, address newFeeReceiver) external onlyOwner {
        require(newFeeReceiver != address(0), "Invalid fee receiver");
        require(newFeePercent <= 100, "Fee percent must be between 0 and 100");

        feePercent = newFeePercent;
        feeReceiver = newFeeReceiver;
    }

    /**
     * @notice Adds or removes an address from the fee exemption list.
     * @param account The address to update.
     * @param exempt True to exempt the account from fees, false to include fees.
     */
    function setExemption(address account, bool exempt) external onlyOwner {
        isExempt[account] = exempt;
    }

    /**
     * @notice Overridden transfer function that applies fee logic.
     *         Non-exempt senders incur a fee, which is sent to feeReceiver.
     * @param recipient The address to receive tokens.
     * @param amount The total amount intended for transfer.
     * @return success A boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (!isExempt[msg.sender] && feePercent > 0) {
            uint256 fee = (amount * feePercent) / 100;
            uint256 netAmount = amount - fee;
            // Transfer fee amount to feeReceiver.
            bool feeSuccess = super.transfer(feeReceiver, fee);
            require(feeSuccess, "Fee transfer failed");
            // Then transfer the net amount to the recipient.
            bool transferSuccess = super.transfer(recipient, netAmount);
            return transferSuccess;
        } else {
            return super.transfer(recipient, amount);
        }
    }

    /**
     * @notice Overridden transferFrom function that applies fee logic.
     *         Non-exempt senders incur a fee, which is transferred to feeReceiver.
     * @param sender The address sending tokens.
     * @param recipient The address receiving tokens.
     * @param amount The total amount intended for transfer.
     * @return success A boolean value indicating whether the operation succeeded.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (!isExempt[sender] && feePercent > 0) {
            uint256 fee = (amount * feePercent) / 100;
            uint256 netAmount = amount - fee;
            // Deduct the total amount from sender's allowance.
            _spendAllowance(sender, _msgSender(), amount);
            // Transfer fee and net amount separately.
            _transfer(sender, feeReceiver, fee);
            _transfer(sender, recipient, netAmount);
            return true;
        } else {
            return super.transferFrom(sender, recipient, amount);
        }
    }
}
