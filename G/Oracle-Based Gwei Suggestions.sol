contract GweiOracleMock {
    uint256 public suggestedGasPrice = 20 gwei;

    function getSuggestedGwei() external view returns (uint256) {
        return suggestedGasPrice / 1 gwei;
    }

    function updateSuggestion(uint256 gweiAmount) external {
        suggestedGasPrice = gweiAmount * 1 gwei;
    }
}
