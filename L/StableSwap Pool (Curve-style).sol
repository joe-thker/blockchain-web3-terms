contract StableSwap {
    uint256 public reserveA;
    uint256 public reserveB;

    function add(uint256 a, uint256 b) external {
        reserveA += a;
        reserveB += b;
    }

    function swap(uint256 amountIn, bool aToB) external returns (uint256 amountOut) {
        if (aToB) {
            amountOut = (amountIn * 1e18) / (1e18 + ((reserveA * 1e18) / reserveB));
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            amountOut = (amountIn * 1e18) / (1e18 + ((reserveB * 1e18) / reserveA));
            reserveB += amountIn;
            reserveA -= amountOut;
        }
    }
}
