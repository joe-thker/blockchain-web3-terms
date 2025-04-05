contract LegacyGasGwei {
    function legacyGasPriceGwei() external view returns (uint256) {
        return tx.gasprice / 1 gwei;
    }
}
