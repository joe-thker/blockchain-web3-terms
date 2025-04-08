// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

/// @title InstantSettlementDEX
/// @notice Simulates instant token swaps with immediate finality
contract InstantSettlementDEX {
    address public tokenA;
    address public tokenB;
    uint256 public exchangeRate; // How many tokenB per 1 tokenA

    event Settled(address indexed user, uint256 inputAmount, uint256 outputAmount);

    constructor(address _tokenA, address _tokenB, uint256 _rate) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        exchangeRate = _rate;
    }

    /// @notice Swap Token A to Token B instantly at fixed rate
    function swap(uint256 amountIn) external {
        require(amountIn > 0, "Invalid amount");
        uint256 amountOut = (amountIn * exchangeRate) / 1e18;

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenB).transfer(msg.sender, amountOut);

        emit Settled(msg.sender, amountIn, amountOut);
    }
}
