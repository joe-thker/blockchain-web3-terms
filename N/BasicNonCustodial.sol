// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BasicNonCustodial
 * @notice A basic non-custodial wallet for Ether.
 *         - Users can deposit Ether, which is credited to an internal balance.
 *         - Only the depositor can withdraw or transfer their funds.
 *         - No admin privileges or fees are applied.
 */
contract BasicNonCustodial {
    /// @notice Mapping from user address to their deposited Ether balance.
    mapping(address => uint256) public balances;

    /// @notice Emitted when a user deposits Ether.
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws Ether.
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Emitted when a user transfers Ether internally.
    event Transferred(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Fallback receive function. Deposits Ether and credits sender’s balance.
     */
    receive() external payable {
        require(msg.value > 0, "Must send non-zero amount");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Deposit Ether into the caller’s internal balance.
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw a specified amount of Ether from the caller’s balance.
     * @param amount The amount to withdraw.
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        // Update balance before transferring to prevent re-entrancy.
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Transfer a specified amount from caller’s balance to another user.
     * @param to The recipient’s address.
     * @param amount The amount to transfer.
     */
    function transferTo(address to, uint256 amount) external {
        require(to != address(0), "Invalid recipient address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transferred(msg.sender, to, amount);
    }
}
