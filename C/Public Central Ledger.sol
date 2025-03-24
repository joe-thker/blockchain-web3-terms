// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PublicCentralLedger
/// @notice A public central ledger where anyone can add ledger entries and view them.
/// Each entry records transaction details including sender, recipient, amount, timestamp, and description.
contract PublicCentralLedger {
    // Structure to store a ledger entry.
    struct LedgerEntry {
        address from;       // Origin of the transaction.
        address to;         // Recipient of the transaction.
        uint256 amount;     // Amount transacted.
        uint256 timestamp;  // Timestamp of the transaction.
        string description; // A brief description of the transaction.
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

    /// @notice Adds a new ledger entry.
    /// @param _from The sender's address.
    /// @param _to The recipient's address.
    /// @param _amount The amount transacted.
    /// @param _description A brief description of the transaction.
    function addEntry(
        address _from,
        address _to,
        uint256 _amount,
        string calldata _description
    ) external {
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
    /// @return from The sender address.
    /// @return to The recipient address.
    /// @return amount The transacted amount.
    /// @return timestamp The timestamp of the entry.
    /// @return description The entry's description.
    function getEntry(uint256 index) external view returns (
        address from,
        address to,
        uint256 amount,
        uint256 timestamp,
        string memory description
    ) {
        require(index < ledger.length, "Index out of bounds");
        LedgerEntry memory entry = ledger[index];
        return (entry.from, entry.to, entry.amount, entry.timestamp, entry.description);
    }
    
    /// @notice Returns the total number of ledger entries.
    /// @return The count of ledger entries.
    function getEntryCount() external view returns (uint256) {
        return ledger.length;
    }
}
