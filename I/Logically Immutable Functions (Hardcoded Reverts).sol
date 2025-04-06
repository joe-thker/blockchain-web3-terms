contract LogicImmutable {
    string[] public messages;

    function addMessage(string calldata msg_) external {
        messages.push(msg_);
    }

    function updateMessage(uint256 index, string calldata) external pure {
        revert("Messages are immutable.");
    }
}
