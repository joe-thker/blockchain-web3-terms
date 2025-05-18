interface IWatchdogRegistry {
    function isThreat(address) external view returns (bool);
}

contract ProtectedProtocol {
    address public immutable watchdog;

    constructor(address _watchdog) {
        watchdog = _watchdog;
    }

    modifier onlySafeInteraction() {
        require(!IWatchdogRegistry(watchdog).isThreat(msg.sender), "Watchdog blocked");
        _;
    }

    function sensitiveAction() external onlySafeInteraction {
        // Action blocked if caller is flagged
    }
}
