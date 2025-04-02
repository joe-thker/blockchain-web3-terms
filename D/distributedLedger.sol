// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DistributedLedger
/// @notice A dynamic, optimized contract for a simple distributed ledger of entries (e.g., transactions).
/// Each entry includes a creator, recipient, amount, optional metadata, and a timestamp.
/// Entries can be removed by their creator or the contract owner.
contract DistributedLedger is Ownable, ReentrancyGuard {
    /// @notice Data structure representing a ledger entry.
    struct LedgerEntry {
        uint256 id;             // Unique ID for this entry
        address creator;        // The address that created the entry
        address recipient;      // The recipient address in this “transaction”
        uint256 amount;         // Some numeric value (e.g., tokens, points, or data quantity)
        string metadata;        // Optional metadata for the entry
        uint256 timestamp;      // Block timestamp when entry was created
        bool active;            // True if entry is active; false if removed
    }

    // Array storing all entries, including removed ones. Index = entryId
    LedgerEntry[] public entries;
    // Next entry ID (same as entries.length)
    uint256 public nextEntryId;

    // --- Events ---
    event EntryAdded(
        uint256 indexed id,
        address indexed creator,
        address indexed recipient,
        uint256 amount,
        string metadata,
        uint256 timestamp
    );
    event EntryRemoved(uint256 indexed id, address indexed remover, uint256 timestamp);

    /// @notice Constructor sets the deployer as the initial owner. 
    /// Use Ownable(msg.sender) to fix the “no arguments to base constructor” issue.
    constructor() Ownable(msg.sender) {}

    /// @notice Adds a new ledger entry with given recipient, amount, and metadata. 
    /// The caller becomes the “creator.”
    /// @param recipient The address that is the recipient in this “transaction.”
    /// @param amount The numeric “amount” or data value for the ledger entry.
    /// @param metadata A string that can store any metadata or notes about the entry.
    /// @return entryId The ID assigned to the new entry in the ledger.
    function addEntry(address recipient, uint256 amount, string calldata metadata)
        external
        nonReentrant
        returns (uint256 entryId)
    {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be > 0");

        entryId = nextEntryId++;
        entries.push(LedgerEntry({
            id: entryId,
            creator: msg.sender,
            recipient: recipient,
            amount: amount,
            metadata: metadata,
            timestamp: block.timestamp,
            active: true
        }));

        emit EntryAdded(entryId, msg.sender, recipient, amount, metadata, block.timestamp);
    }

    /// @notice Removes (marks inactive) a ledger entry. 
    /// Only the entry’s creator or the contract owner can remove it.
    /// @param entryId The ID of the ledger entry to remove.
    function removeEntry(uint256 entryId) external nonReentrant {
        require(entryId < entries.length, "Invalid entry ID");
        LedgerEntry storage ent = entries[entryId];
        require(ent.active, "Entry already removed");
        require(
            msg.sender == ent.creator || msg.sender == owner(),
            "Not authorized to remove"
        );

        ent.active = false;
        emit EntryRemoved(entryId, msg.sender, block.timestamp);
    }

    /// @notice Retrieves the total number of entries ever created (including removed).
    /// @return The length of the entries array.
    function totalEntries() external view returns (uint256) {
        return entries.length;
    }

    /// @notice Retrieves the LedgerEntry struct for a given entry ID.
    /// @param entryId The ID of the entry.
    /// @return A LedgerEntry struct with details.
    function getEntry(uint256 entryId) external view returns (LedgerEntry memory) {
        require(entryId < entries.length, "Invalid entry ID");
        return entries[entryId];
    }

    /// @notice Returns a list of currently active entries in the ledger.
    /// @return A dynamic array of all active LedgerEntry structs.
    function listActiveEntries() external view returns (LedgerEntry[] memory) {
        // Count how many are active
        uint256 count;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].active) {
                count++;
            }
        }
        LedgerEntry[] memory active = new LedgerEntry[](count);
        uint256 idx;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].active) {
                active[idx++] = entries[i];
            }
        }
        return active;
    }
}
