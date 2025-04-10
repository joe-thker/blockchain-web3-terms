contract PreAddLiquidityHook {
    event BeforeAddLiquidity(address user, uint256 amount);

    function beforeAddLiquidity(address user, uint256 amount) external {
        require(amount >= 1 ether, "Minimum liquidity required");
        emit BeforeAddLiquidity(user, amount);
    }
}
