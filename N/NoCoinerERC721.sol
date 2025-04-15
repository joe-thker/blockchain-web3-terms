// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Using OpenZeppelin contracts compatible with v3.x
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NoCoiner
 * @notice ERC20 token with a dynamic fee mechanism.
 *         In this version the fee logic is embedded in transfer and transferFrom.
 */
contract NoCoiner is ERC20, Ownable {
    uint256 public feePercent;
    address public feeReceiver;

    /**
     * @dev Constructor initializes token parameters.
     * @param initialSupply Total token supply minted to the deployer.
     * @param _feePercent Fee percentage (0-100).
     * @param _feeReceiver Address that receives the fees.
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
     * @notice Updates fee settings.
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
     * @notice Overridden transfer function that applies fee for non-owner transfers.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (msg.sender != owner() && feePercent > 0) {
            uint256 fee = (amount * feePercent) / 100;
            uint256 netAmount = amount - fee;
            // Send fee to feeReceiver
            bool feeSuccess = super.transfer(feeReceiver, fee);
            require(feeSuccess, "Fee transfer failed");
            // Transfer remaining tokens to recipient
            bool transferSuccess = super.transfer(recipient, netAmount);
            return transferSuccess;
        } else {
            return super.transfer(recipient, amount);
        }
    }

    /**
     * @notice Overridden transferFrom function that applies fee for non-owner transfers.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (sender != owner() && feePercent > 0) {
            uint256 fee = (amount * feePercent) / 100;
            uint256 netAmount = amount - fee;
            // Deduct the total amount from the sender's allowance
            _spendAllowance(sender, _msgSender(), amount);
            // Directly call _transfer for both fee and net transfers
            _transfer(sender, feeReceiver, fee);
            _transfer(sender, recipient, netAmount);
            return true;
        } else {
            return super.transferFrom(sender, recipient, amount);
        }
    }
}
