// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NonCustodialWithFee
 * @notice A non-custodial wallet for Ether with a fee mechanism.
 *         Users can deposit and withdraw Ether. On withdrawal, a fee is deducted
 *         and transferred to the designated fee receiver.
 *         The owner (admin) can update the fee settings but cannot access user funds.
 */
contract NonCustodialWithFee is Ownable {
    /// @notice Mapping from user addresses to their Ether balances.
    mapping(address => uint256) public balances;
    
    /// @notice Address that will receive the withdrawal fees.
    address public feeReceiver;
    
    /// @notice Fee percentage (0 to 100) applied on withdrawal.
    uint256 public feePercent;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 netAmount, uint256 fee);
    event Transferred(address indexed from, address indexed to, uint256 amount);
    event FeeUpdated(uint256 newFeePercent, address newFeeReceiver);

    /**
     * @dev Constructor sets the initial fee parameters and initializes the Ownable contract.
     * @param _feePercent Initial fee percentage (must be between 0 and 100).
     * @param _feeReceiver Address that will receive the withdrawal fees.
     */
    constructor(uint256 _feePercent, address _feeReceiver) Ownable(msg.sender) {
        require(_feeReceiver != address(0), "Invalid fee receiver");
        require(_feePercent <= 100, "Fee percent must be between 0 and 100");
        feePercent = _feePercent;
        feeReceiver = _feeReceiver;
    }

    /**
     * @notice Fallback receive function.
     *         Deposits Ether and credits the sender's balance.
     */
    receive() external payable {
        require(msg.value > 0, "Must send non-zero amount");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Deposit Ether into the caller's internal balance.
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraws a specified amount of Ether after deducting a fee.
     * @param amount The total amount (before fee) to withdraw.
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        // Calculate fee and net amount.
        uint256 fee = (amount * feePercent) / 100;
        uint256 netAmount = amount - fee;
        // Update balance before transfers to prevent re-entrancy.
        balances[msg.sender] -= amount;
        // Transfer net amount to the user.
        payable(msg.sender).transfer(netAmount);
        // Transfer fee to feeReceiver.
        payable(feeReceiver).transfer(fee);
        emit Withdrawn(msg.sender, netAmount, fee);
    }

    /**
     * @notice Transfers a specified amount from the caller's balance to another address.
     * @param to The recipient address.
     * @param amount The amount to transfer.
     */
    function transferTo(address to, uint256 amount) external {
        require(to != address(0), "Invalid recipient address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transferred(msg.sender, to, amount);
    }

    /**
     * @notice Updates the fee parameters (percentage and fee receiver).
     *         Only the contract owner may call this function.
     * @param newFeePercent The new fee percentage (0 to 100).
     * @param newFeeReceiver The new fee receiver address.
     */
    function updateFeeParameters(uint256 newFeePercent, address newFeeReceiver) external onlyOwner {
        require(newFeeReceiver != address(0), "Invalid fee receiver");
        require(newFeePercent <= 100, "Fee percent must be between 0 and 100");
        feePercent = newFeePercent;
        feeReceiver = newFeeReceiver;
        emit FeeUpdated(newFeePercent, newFeeReceiver);
    }
}
