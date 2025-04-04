contract PriorityFeeCalculator {
    function getPriorityFee() external view returns (uint256) {
        return tx.gasprice - block.basefee;
    }
}
