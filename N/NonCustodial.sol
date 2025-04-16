// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NonCustodial
 * @notice A non-custodial wallet smart contract.
 *         Users can deposit Ether, which is credited to an internal balance ledger.
 *         Only the individual depositor can withdraw or transfer their funds.
 *         This contract does not allow any third party or admin to seize user funds.
 */
contract NonCustodial {
    /// @notice Mapping from user address to their deposited balance.
    mapping(address => uint256) public balances;

    /// @notice Emitted when a user deposits Ether.
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws Ether.
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Emitted when a user transfers funds to another address within the wallet.
    event Transferred(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Fallback receive function that credits the sender’s balance when Ether is sent directly.
     */
    receive() external payable {
        require(msg.value > 0, "Must send non-zero amount");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Deposits Ether into the caller’s internal balance.
     * @dev The function is payable to allow Ether to be sent.
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows the caller to withdraw a specified amount of Ether.
     * @param amount The amount to withdraw.
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        // Update the balance before transferring to avoid re-entrancy issues.
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Allows a user to transfer a specified amount from their balance to another address within the system.
     * @param to The recipient address.
     * @param amount The amount to transfer.
     */
    function transferTo(address to, uint256 amount) external {
        require(to != address(0), "Invalid recipient address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Adjust balances
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transferred(msg.sender, to, amount);
    }
}
