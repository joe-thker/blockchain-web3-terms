contract HardLiquidation {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    function liquidate(address borrower) external {
        require(debt[borrower] > collateral[borrower], "Not undercollateralized");

        delete debt[borrower];
        delete collateral[borrower];

        // Collateral seized by protocol or liquidator
    }
}
