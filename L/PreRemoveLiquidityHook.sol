contract PreRemoveLiquidityHook {
    event BeforeRemoveLiquidity(address indexed user, uint256 lpAmount);

    function beforeRemoveLiquidity(address user, uint256 lpAmount) external {
        require(lpAmount <= 100 ether, "Max removal exceeded");
        emit BeforeRemoveLiquidity(user, lpAmount);
    }
}
