// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Liquidity Hook – Fee-on-Add Hook
contract LiquidityHook {
    address public dao;
    uint256 public feeBps = 100; // 1%

    constructor(address _dao) {
        dao = _dao;
    }

    /// @notice Called when liquidity is added
    function onAddLiquidity(address user, uint256 amount) external returns (uint256 adjustedAmount) {
        uint256 fee = (amount * feeBps) / 10_000;
        payable(dao).transfer(fee);
        adjustedAmount = amount - fee;
    }

    // Could also define:
    // - onRemoveLiquidity()
    // - beforeSwap()
    // - afterSwap()
}
