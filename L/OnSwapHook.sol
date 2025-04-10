contract OnSwapHook {
    event SwapTriggered(address from, address to, uint256 amountIn, uint256 amountOut);

    function onSwap(address from, address to, uint256 inAmount, uint256 outAmount) external {
        // Add custom logic: logging, fees, slippage tracking
        emit SwapTriggered(from, to, inAmount, outAmount);
    }
}
