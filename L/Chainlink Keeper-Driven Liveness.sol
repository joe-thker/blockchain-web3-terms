interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata) external returns (bool, bytes memory);
    function performUpkeep(bytes calldata) external;
}

contract KeeperLiveness is KeeperCompatibleInterface {
    uint256 public lastPing;
    uint256 public interval = 1 hours;

    constructor() {
        lastPing = block.timestamp;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp - lastPing) > interval;
    }

    function performUpkeep(bytes calldata) external override {
        require((block.timestamp - lastPing) > interval, "Still within interval");
        lastPing = block.timestamp;
    }
}
