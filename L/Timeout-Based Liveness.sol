contract TimeoutLiveness {
    uint256 public lastAction;
    uint256 public timeout = 10 minutes;

    constructor() {
        lastAction = block.timestamp;
    }

    function update() external {
        lastAction = block.timestamp;
    }

    function forceProgress() external {
        require(block.timestamp > lastAction + timeout, "Too early");
        lastAction = block.timestamp;
        // Auto-progress to next state
    }
}
