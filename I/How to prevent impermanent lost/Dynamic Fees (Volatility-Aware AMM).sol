contract VolatilityAwareFee {
    uint256 public baseFee = 30; // 0.3%
    uint256 public dynamicFee;

    function setVolatilityLevel(uint256 volatility) external {
        // Simulate dynamic fee: higher volatility = higher fee
        dynamicFee = baseFee + (volatility * 10);
    }

    function getCurrentFee() public view returns (uint256) {
        return dynamicFee;
    }
}
