contract GweiRefundSimulator {
    event GasUsed(uint256 gasUsed, uint256 gasRefundedGwei);

    function simulateRefund() external {
        uint256 startGas = gasleft();
        uint256 dummy;

        for (uint i = 0; i < 100; i++) {
            dummy += i; // just burn some gas
        }

        uint256 used = startGas - gasleft();
        uint256 refunded = tx.gasprice * gasleft();

        emit GasUsed(used, refunded / 1 gwei);
    }
}
