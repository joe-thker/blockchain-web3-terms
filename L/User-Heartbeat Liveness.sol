contract HeartbeatLiveness {
    mapping(address => uint256) public lastPing;
    uint256 public expiry = 3 days;

    function ping() external {
        lastPing[msg.sender] = block.timestamp;
    }

    function isAlive(address user) external view returns (bool) {
        return block.timestamp <= lastPing[user] + expiry;
    }
}
