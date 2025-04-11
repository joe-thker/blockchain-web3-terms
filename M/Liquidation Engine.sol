contract LiquidationEngine {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;
    uint256 public ethPrice = 2000e18;
    uint256 public liquidationRatio = 130;

    function updatePrice(uint256 price) external {
        ethPrice = price;
    }

    function checkLiquidation(address user) public view returns (bool) {
        uint256 value = collateral[user] * ethPrice / 1e18;
        return value * 100 < debt[user] * liquidationRatio;
    }

    function liquidate(address user) external {
        require(checkLiquidation(user), "Still healthy");
        collateral[user] = 0;
        debt[user] = 0;
        // Auction logic or reward goes here
    }
}
