// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract LiquidityPool {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public totalShares;
    mapping(address => uint256) public shares;

    uint256 public reserveA;
    uint256 public reserveB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 share;
        if (totalShares == 0) {
            share = sqrt(amountA * amountB);
        } else {
            share = min((amountA * totalShares) / reserveA, (amountB * totalShares) / reserveB);
        }

        require(share > 0, "Insufficient liquidity added");

        shares[msg.sender] += share;
        totalShares += share;

        reserveA += amountA;
        reserveB += amountB;
    }

    function removeLiquidity(uint256 share) external {
        require(shares[msg.sender] >= share, "Not enough share");

        uint256 amountA = (share * reserveA) / totalShares;
        uint256 amountB = (share * reserveB) / totalShares;

        shares[msg.sender] -= share;
        totalShares -= share;

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}
