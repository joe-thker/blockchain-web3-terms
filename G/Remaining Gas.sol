contract GasLeftLogger {
    event RemainingGas(uint256 gas);

    function logMidwayGas() external {
        emit RemainingGas(gasleft());

        for (uint256 i = 0; i < 100; i++) {
            // burn gas
        }

        emit RemainingGas(gasleft());
    }
}
