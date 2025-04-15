// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin contracts (compatible with v3.x)
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NoCoiner
 * @notice ERC20 token with a dynamic fee mechanism.
 *         Overrides transfer and transferFrom to include a fee for non-owner transfers.
 */
contract NoCoiner is ERC20, Ownable {
    uint256 public feePercent;
    address public feeReceiver;

    /**
     * @dev Constructor. Initializes the token with name, symbol, initial supply and fee settings.
     * @param initialSupply The total initial supply minted to the deployer.
     * @param _feePercent The fee percent (0-100) for transfers.
     * @param _feeReceiver The address that receives the fee.
     */
    constructor(
        uint256 initialSupply,
        uint256 _feePercent,
        address _feeReceiver
    )
        ERC20("NoCoiner", "NOC")
        Ownable(msg.sender)
    {
        require(_feeReceiver != address(0), "Invalid fee receiver");
        require(_feePercent <= 100, "Fee percent must be between 0 and 100");
        feePercent = _feePercent;
        feeReceiver = _feeReceiver;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Allows the owner to update the fee settings.
     * @param newFeePercent New fee percentage (0-100).
     * @param newFeeReceiver New address to receive transfer fees.
     */
    function updateFee(uint256 newFeePercent, address newFeeReceiver) external onlyOwner {
        require(newFeeReceiver != address(0), "Invalid fee receiver");
        require(newFeePercent <= 100, "Fee percent must be between 0 and 100");
        feePercent = newFeePercent;
        feeReceiver = newFeeReceiver;
    }

    /**
     * @notice Overridden transfer function to include fee logic.
     *         Transfers initiated by the owner are exempt from fees.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (msg.sender != owner() && feePercent > 0) {
            uint256 fee = (amount * feePercent) / 100;
            uint256 netAmount = amount - fee;
            // Transfer the fee first
            bool feeSuccess = super.transfer(feeReceiver, fee);
            require(feeSuccess, "Fee transfer failed");
            // Then transfer the remaining amount
            bool transferSuccess = super.transfer(recipient, netAmount);
            return transferSuccess;
        } else {
            return super.transfer(recipient, amount);
        }
    }

    /**
     * @notice Overridden transferFrom function to include fee logic.
     *         Transfers initiated by the owner are exempt from fees.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (sender != owner() && feePercent > 0) {
            uint256 fee = (amount * feePercent) / 100;
            uint256 netAmount = amount - fee;
            // Deduct fee from sender: first, spend the total allowance.
            _spendAllowance(sender, _msgSender(), amount);
            // Manually call _transfer for fee and net amount
            _transfer(sender, feeReceiver, fee);
            _transfer(sender, recipient, netAmount);
            return true;
        } else {
            return super.transferFrom(sender, recipient, amount);
        }
    }
}
