contract MaxFeeTracker {
    event FeeSet(address indexed sender, uint256 maxFeeGwei);

    function simulateMaxFee(uint256 gweiAmount) external {
        emit FeeSet(msg.sender, gweiAmount);
    }
}
