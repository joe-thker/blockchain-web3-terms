contract GasPriceTracker {
    event GasPrice(uint256 gasPrice);

    function getTxGasPrice() external {
        emit GasPrice(tx.gasprice);
    }
}
