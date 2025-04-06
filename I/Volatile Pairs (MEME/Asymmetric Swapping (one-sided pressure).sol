function simulateUnbalancedSwap(uint256 amountIn) external {
    // User only swaps TokenA into the pool, causing reserveA ↑ and reserveB ↓
    swapAforB(amountIn); // uses inherited swap logic
}
