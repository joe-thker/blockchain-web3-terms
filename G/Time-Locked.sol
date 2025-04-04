contract TimeLockedGov {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock) public locks;

    function lock(uint256 amount, uint256 duration) external {
        require(duration <= 4 * 365 days, "Max 4 years");
        locks[msg.sender] = Lock(amount, block.timestamp + duration);
    }

    function getVotingPower(address user) public view returns (uint256) {
        Lock memory l = locks[user];
        if (block.timestamp >= l.unlockTime) return 0;
        uint256 remaining = l.unlockTime - block.timestamp;
        return (l.amount * remaining) / (4 * 365 days); // max boost = full lock
    }
}
