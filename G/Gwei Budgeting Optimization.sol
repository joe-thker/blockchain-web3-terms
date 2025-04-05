contract GweiBudget {
    uint256 public gasLimit = 21000;

    function estimatedTxCost(uint256 gweiPrice) external view returns (uint256 weiCost) {
        weiCost = gasLimit * gweiPrice * 1 gwei;
    }
}
