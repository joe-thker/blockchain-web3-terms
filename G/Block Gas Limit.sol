contract BlockGasLimitViewer {
    function getBlockGasLimit() external view returns (uint256) {
        return block.gaslimit;
    }
}
