contract SoftLiquidation {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    function liquidate(address borrower, uint256 repayAmount) external {
        require(debt[borrower] > collateral[borrower], "Healthy position");

        uint256 liquidationAmount = repayAmount / 2; // only partial
        require(debt[borrower] >= liquidationAmount, "Too much");

        debt[borrower] -= liquidationAmount;
        collateral[borrower] -= liquidationAmount;
    }
}
