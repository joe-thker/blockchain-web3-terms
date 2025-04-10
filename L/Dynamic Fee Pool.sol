contract DynamicFeeAMM {
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public feeBasisPoints = 30;

    function setFee(uint256 bps) external {
        require(bps <= 100, "Max 1%");
        feeBasisPoints = bps;
    }

    function swap(uint256 amountIn, bool zeroForOne) external {
        uint256 amountInWithFee = (amountIn * (10000 - feeBasisPoints)) / 10000;
        if (zeroForOne) {
            uint256 out = (amountInWithFee * reserve1) / (reserve0 + amountInWithFee);
            reserve0 += amountIn;
            reserve1 -= out;
        } else {
            uint256 out = (amountInWithFee * reserve0) / (reserve1 + amountInWithFee);
            reserve1 += amountIn;
            reserve0 -= out;
        }
    }
}
