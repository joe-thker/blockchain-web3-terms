contract GasUsedTracker {
    event GasUsed(uint256 used);

    function simulateGasUsage() external {
        uint256 start = gasleft();

        uint256 dummy;
        for (uint256 i = 0; i < 100; i++) {
            dummy += i;
        }

        uint256 end = gasleft();
        emit GasUsed(start - end);
    }
}
