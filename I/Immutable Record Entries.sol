contract ImmutableLedger {
    struct Entry {
        address writer;
        string data;
        uint256 timestamp;
    }

    Entry[] public entries;

    function writeEntry(string calldata data) external {
        entries.push(Entry(msg.sender, data, block.timestamp));
    }

    function updateEntry(uint256, string calldata) external pure {
        revert("Entry is immutable.");
    }

    function getEntry(uint256 index) external view returns (Entry memory) {
        return entries[index];
    }
}
