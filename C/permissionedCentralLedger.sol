// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PermissionedCentralLedger
/// @notice A centralized ledger that records financial transactions.
/// Only authorized addresses (managed by the owner) can add new ledger entries.
contract PermissionedCentralLedger {
    address public owner;
    
    // Mapping to track authorized addresses that can add ledger entries.
    mapping(address => bool) public authorized;
    
    // Structure to store a ledger entry.
    struct LedgerEntry {
        address from;       // Origin of the transaction.
        address to;         // Recipient of the transaction.
        uint256 amount;     // Amount transacted.
        uint256 timestamp;  // Timestamp of the transaction.
        string description; // A brief description of the transaction.
    }
    
    // Dynamic array of ledger entries.
    LedgerEntry[] public ledger;
    
    // Events to log ledger entries and authorization changes.
    event EntryAdded(
        uint256 indexed entryId,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 timestamp,
        string description
    );
    event AuthorizationGranted(address indexed addr);
    event AuthorizationRevoked(address indexed addr);

    // Modifier to restrict functions to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    // Modifier to restrict functions to authorized addresses (or the owner).
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || msg.sender == owner, "Not authorized");
        _;
    }

    /// @notice Constructor sets the deployer as the owner and grants them authorization.
    constructor() {
        owner = msg.sender;
        authorized[msg.sender] = true;
    }

    /// @notice Grants authorization to an address to add ledger entries.
    /// @param addr The address to authorize.
    function grantAuthorization(address addr) external onlyOwner {
        authorized[addr] = true;
        emit AuthorizationGranted(addr);
    }

    /// @notice Revokes authorization from an address.
    /// @param addr The address to revoke.
    function revokeAuthorization(address addr) external onlyOwner {
        authorized[addr] = false;
        emit AuthorizationRevoked(addr);
    }

    /// @notice Adds a new ledger entry.
    /// @param _from The sender address.
    /// @param _to The recipient address.
    /// @param _amount The amount transacted.
    /// @param _description A brief description of the transaction.
    function addEntry(
        address _from,
        address _to,
        uint256 _amount,
        string calldata _description
    ) external onlyAuthorized {
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

    /// @notice Retrieves a ledger entry by index.
    /// @param index The index of the entry.
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
        LedgerEntry storage entry = ledger[index];
        return (entry.from, entry.to, entry.amount, entry.timestamp, entry.description);
    }

    /// @notice Returns the total number of ledger entries.
    /// @return The count of ledger entries.
    function getEntryCount() external view returns (uint256) {
        return ledger.length;
    }
}
