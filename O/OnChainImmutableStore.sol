// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OnChainImmutableStore
 * @notice Publish‑once key/value registry.
 *         – Anyone can publish a key exactly once.
 *         – Owner can freeze/unfreeze further writes.
 */
contract OnChainImmutableStore {
    struct Entry {
        address publisher;
        uint256 timestamp;
        string  value;
    }

    mapping(string => Entry) private entries;
    address public immutable owner;
    bool    public frozen;

    event EntryPublished(string indexed key, address indexed publisher, string value);
    event Frozen();
    event Unfrozen();

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }

    constructor() {
        owner = msg.sender;
    }

    function publish(string calldata key, string calldata value) external {
        require(!frozen, "frozen");
        require(entries[key].timestamp == 0, "exists");
        entries[key] = Entry(msg.sender, block.timestamp, value);
        emit EntryPublished(key, msg.sender, value);
    }

    function get(string calldata key)
        external
        view
        returns (address publisher, uint256 timestamp, string memory value)
    {
        Entry storage e = entries[key];
        require(e.timestamp != 0, "not found");
        return (e.publisher, e.timestamp, e.value);
    }

    function freeze() external onlyOwner { frozen = true;  emit Frozen(); }
    function unfreeze() external onlyOwner { frozen = false; emit Unfrozen(); }
}
