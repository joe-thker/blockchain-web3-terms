contract KeeperLiquidation {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    function isLiquidatable(address borrower) public view returns (bool) {
        return debt[borrower] > collateral[borrower];
    }

    function triggerLiquidation(address borrower) external {
        require(isLiquidatable(borrower), "Not eligible");
        delete debt[borrower];
        delete collateral[borrower];
        // Liquidator could receive reward here
    }
}
