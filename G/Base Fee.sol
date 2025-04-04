contract BaseFeeViewer {
    function getBaseFee() external view returns (uint256) {
        return block.basefee;
    }
}
