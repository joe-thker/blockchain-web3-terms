contract PostAddLiquidityHook {
    event AfterAddLiquidity(address indexed user, uint256 tokensMinted);

    function afterAddLiquidity(address user, uint256 lpTokens) external {
        emit AfterAddLiquidity(user, lpTokens);
    }
}
