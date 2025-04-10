contract PostRemoveLiquidityHook {
    event AfterRemoveLiquidity(address user, uint256 ethReturned, uint256 tokenReturned);

    function afterRemoveLiquidity(address user, uint256 ethOut, uint256 tokenOut) external {
        emit AfterRemoveLiquidity(user, ethOut, tokenOut);
    }
}
