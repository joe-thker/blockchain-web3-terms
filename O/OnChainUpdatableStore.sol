// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OnChainUpdatableStore
 * @notice Mutable registry.
 *         – Uploader (or owner) can update or delete a key.
 *         – Owner can pause/unpause all write operations.
 */
contract OnChainUpdatableStore {
    struct Entry {
        address uploader;
        uint256 timestamp;
        string  value;
        bool    exists;
    }

    mapping(string => Entry) private entries;
    address public immutable owner;
    bool    public paused;

    event EntrySet(string indexed key, address indexed uploader, string value);
    event EntryDeleted(string indexed key, address indexed by);
    event Paused();
    event Unpaused();

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }
    modifier notPaused() { require(!paused, "paused"); _; }

    constructor() { owner = msg.sender; }

    function set(string calldata key, string calldata value) external notPaused {
        Entry storage e = entries[key];
        if (e.exists) {
            require(e.uploader == msg.sender || msg.sender == owner, "unauthorized");
            e.value     = value;
            e.timestamp = block.timestamp;
        } else {
            entries[key] = Entry(msg.sender, block.timestamp, value, true);
        }
        emit EntrySet(key, msg.sender, value);
    }

    function del(string calldata key) external notPaused {
        Entry storage e = entries[key];
        require(e.exists, "not found");
        require(e.uploader == msg.sender || msg.sender == owner, "unauthorized");
        delete entries[key];
        emit EntryDeleted(key, msg.sender);
    }

    function get(string calldata key) external view returns (Entry memory) {
        return entries[key];
    }

    function pause()   external onlyOwner { paused = true;  emit Paused();   }
    function unpause() external onlyOwner { paused = false; emit Unpaused(); }
}
