contract PriorityFeeGwei {
    function getPriorityTipGwei() external view returns (uint256) {
        return (tx.gasprice - block.basefee) / 1 gwei;
    }
}
