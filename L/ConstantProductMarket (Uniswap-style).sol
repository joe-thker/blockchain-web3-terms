// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ConstantProductMarket {
    uint256 public reserveX;
    uint256 public reserveY;

    constructor(uint256 _x, uint256 _y) {
        reserveX = _x;
        reserveY = _y;
    }

    function getPrice(uint256 dx) public view returns (uint256 dy) {
        uint256 newX = reserveX + dx;
        uint256 newY = (reserveX * reserveY) / newX;
        dy = reserveY - newY;
    }

    function swap(uint256 dx) external returns (uint256 dy) {
        dy = getPrice(dx);
        reserveX += dx;
        reserveY -= dy;
    }
}
