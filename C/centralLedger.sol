// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CentralLedger
/// @notice This contract simulates a centralized ledger system for recording financial transactions.
contract CentralLedger {
    address public owner;

    // Struct to store a ledger entry.
    struct LedgerEntry {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        string description;
    }

    // Dynamic array to store all ledger entries.
    LedgerEntry[] public ledger;

    // Event emitted when a new ledger entry is added.
    event EntryAdded(
        uint256 indexed entryId,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 timestamp,
        string description
    );

    // Modifier to restrict functions to the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Adds a new ledger entry. Only the owner can call this function.
    /// @param _from The address from which the transaction originates.
    /// @param _to The address to which the transaction is sent.
    /// @param _amount The amount transacted.
    /// @param _description A description of the transaction.
    function addEntry(
        address _from,
        address _to,
        uint256 _amount,
        string calldata _description
    ) external onlyOwner {
        LedgerEntry memory entry = LedgerEntry({
            from: _from,
            to: _to,
            amount: _amount,
            timestamp: block.timestamp,
            description: _description
        });
        ledger.push(entry);
        emit EntryAdded(ledger.length - 1, _from, _to, _amount, block.timestamp, _description);
    }

    /// @notice Retrieves a ledger entry by its index.
    /// @param index The index of the ledger entry.
    /// @return from The address from which the transaction originated.
    /// @return to The address to which the transaction is sent.
    /// @return amount The amount transacted.
    /// @return timestamp The timestamp of the transaction.
    /// @return description A description of the transaction.
    function getEntry(uint256 index) external view returns (
        address from,
        address to,
        uint256 amount,
        uint256 timestamp,
        string memory description
    ) {
        require(index < ledger.length, "Index out of bounds");
        LedgerEntry storage entry = ledger[index];
        return (entry.from, entry.to, entry.amount, entry.timestamp, entry.description);
    }

    /// @notice Returns the total number of ledger entries.
    /// @return The count of ledger entries.
    function getEntryCount() external view returns (uint256) {
        return ledger.length;
    }
}
