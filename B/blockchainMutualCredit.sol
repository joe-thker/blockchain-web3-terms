// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title MutualCreditSystem
/// @notice A simple blockchain mutual credit system where participants' balances can be positive or negative.
///         The contract owner can issue credit, and participants can transfer credit among themselves.
///         Negative balances are allowed up to a specified credit limit.
contract MutualCreditSystem {
    address public owner;
    
    // Mapping to store credit balances (can be positive for credit or negative for debt).
    mapping(address => int256) public creditBalance;

    // Define a credit limit for participants (for example, they cannot have a balance lower than -1000).
    int256 public constant CREDIT_LIMIT = -1000;

    // Events to log credit issuance and transfers.
    event CreditIssued(address indexed to, int256 amount);
    event CreditTransferred(address indexed from, address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Allows the owner to issue positive credit to a participant.
    /// @param account The address to which credit is issued.
    /// @param amount The amount of credit to issue (must be positive).
    function issueCredit(address account, int256 amount) external onlyOwner {
        require(amount > 0, "Amount must be positive");
        creditBalance[account] += amount;
        emit CreditIssued(account, amount);
    }

    /// @notice Allows a participant to transfer credit to another participant.
    /// @param to The recipient address.
    /// @param amount The amount of credit to transfer (must be positive).
    function transferCredit(address to, uint256 amount) external {
        require(amount > 0, "Transfer amount must be positive");
        // Convert amount to int256 for arithmetic.
        int256 amt = int256(amount);
        // Ensure that after transferring, the sender's balance doesn't drop below the credit limit.
        require(creditBalance[msg.sender] - amt >= CREDIT_LIMIT, "Sender credit limit exceeded");
        
        creditBalance[msg.sender] -= amt;
        creditBalance[to] += amt;
        emit CreditTransferred(msg.sender, to, amount);
    }

    /// @notice Returns the current credit balance for a given account.
    /// @param account The address of the account.
    /// @return The credit balance (can be positive or negative).
    function getCreditBalance(address account) external view returns (int256) {
        return creditBalance[account];
    }
}
