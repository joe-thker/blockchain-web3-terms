contract ShardedMainChain {
    mapping(uint256 => bytes32) public shardHeads;

    event ShardUpdated(uint256 shardId, bytes32 newRoot);

    function updateShard(uint256 shardId, bytes32 newRoot) external {
        shardHeads[shardId] = newRoot;
        emit ShardUpdated(shardId, newRoot);
    }

    function getShardState(uint256 shardId) external view returns (bytes32) {
        return shardHeads[shardId];
    }
}
