// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OnChainRegistry
 * @notice A fully on‑chain key‑value store.
 *         – Anyone can publish key/value pairs (string → string).
 *         – Entries are immutable once written (“on‑chain permanence”).
 *         – Owner can freeze or unfreeze the contract if needed.
 *
 *         This illustrates a pure “on‑chain” pattern: all data lives inside
 *         contract storage; no external dependencies or off‑chain pointers.
 */
contract OnChainRegistry is Ownable {
    struct Entry {
        address publisher;  // who wrote it
        uint256 timestamp;  // block.timestamp when written
        string  value;      // stored value
        bool    exists;     // guard flag
    }

    /// @notice mapping of key → Entry
    mapping(string => Entry) private entries;

    /// @notice global write‑lock flag
    bool public frozen;

    event EntryPublished(string indexed key, address indexed publisher, string value);
    event Frozen();
    event Unfrozen();

    constructor() Ownable(msg.sender) {}

    // ─────────────────────────────────────────────────────────────
    // Write operations
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Publish a new entry. Fails if the key already exists or contract frozen.
     * @param key   The UTF‑8 key string.
     * @param value The UTF‑8 value string.
     */
    function publish(string calldata key, string calldata value) external {
        require(!frozen,                 "Registry: frozen");
        require(!entries[key].exists,    "Registry: key exists");

        entries[key] = Entry({
            publisher: msg.sender,
            timestamp: block.timestamp,
            value: value,
            exists: true
        });

        emit EntryPublished(key, msg.sender, value);
    }

    /**
     * @notice Freeze further writes (owner‑only).
     *         Use in emergencies or after snapshot is complete.
     */
    function freeze() external onlyOwner {
        frozen = true;
        emit Frozen();
    }

    /**
     * @notice Unfreeze writes (owner‑only).
     */
    function unfreeze() external onlyOwner {
        frozen = false;
        emit Unfrozen();
    }

    // ─────────────────────────────────────────────────────────────
    // Read operations
    // ─────────────────────────────────────────────────────────────

    /**
     * @notice Retrieve an entry by key.
     * @param key The key string.
     * @return publisher Who wrote it.
     * @return timestamp When it was written.
     * @return value     The stored value.
     */
    function get(string calldata key)
        external
        view
        returns (address publisher, uint256 timestamp, string memory value)
    {
        Entry storage e = entries[key];
        require(e.exists, "Registry: key not found");
        return (e.publisher, e.timestamp, e.value);
    }

    /**
     * @notice Check if a key exists.
     */
    function exists(string calldata key) external view returns (bool) {
        return entries[key].exists;
    }
}
