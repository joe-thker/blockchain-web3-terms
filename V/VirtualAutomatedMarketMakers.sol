// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOracle {
    function getPrice() external view returns (uint256);
}

contract vAMM {
    address public immutable oracle;
    address public immutable admin;
    uint256 public virtualX; // Base asset
    uint256 public virtualY; // Quote asset

    struct Position {
        int256 size; // positive = long, negative = short
        uint256 margin;
        uint256 entryPrice;
    }

    mapping(address => Position) public positions;
    mapping(address => uint256) public collateral;

    event Opened(address indexed trader, int256 size, uint256 price);
    event Closed(address indexed trader, int256 size, uint256 price, int256 pnl);

    constructor(address _oracle, uint256 _x, uint256 _y) {
        oracle = _oracle;
        admin = msg.sender;
        virtualX = _x;
        virtualY = _y;
    }

    function deposit() external payable {
        collateral[msg.sender] += msg.value;
    }

    function getMarkPrice() public view returns (uint256) {
        return (virtualY * 1e18) / virtualX;
    }

    function openPosition(int256 sizeDelta) external {
        require(sizeDelta != 0, "Invalid size");

        uint256 markPrice = getMarkPrice();
        Position storage p = positions[msg.sender];
        int256 newSize = p.size + sizeDelta;

        uint256 marginRequired = (uint256(abs(sizeDelta)) * markPrice) / 1e18;
        require(collateral[msg.sender] >= marginRequired, "Insufficient margin");

        // Adjust virtual reserves (constant product: x * y = k)
        if (sizeDelta > 0) {
            virtualX -= uint256(sizeDelta);
            virtualY = (virtualX * virtualY) / (virtualX + uint256(sizeDelta));
        } else {
            virtualX += uint256(-sizeDelta);
            virtualY = (virtualX * virtualY) / (virtualX - uint256(-sizeDelta));
        }

        p.size = newSize;
        p.entryPrice = markPrice;
        p.margin += marginRequired;
        collateral[msg.sender] -= marginRequired;

        emit Opened(msg.sender, sizeDelta, markPrice);
    }

    function closePosition() external {
        Position storage p = positions[msg.sender];
        require(p.size != 0, "No position");

        uint256 markPrice = getMarkPrice();
        int256 pnl = computePnL(p.size, p.entryPrice, markPrice);

        // Update virtual reserves in reverse
        if (p.size > 0) {
            virtualX += uint256(p.size);
        } else {
            virtualX -= uint256(-p.size);
        }

        collateral[msg.sender] += p.margin;
        if (pnl > 0) {
            collateral[msg.sender] += uint256(pnl);
        } else {
            collateral[msg.sender] -= uint256(-pnl);
        }

        emit Closed(msg.sender, p.size, markPrice, pnl);

        delete positions[msg.sender];
    }

    function computePnL(int256 size, uint256 entryPrice, uint256 exitPrice) internal pure returns (int256) {
        return size * int256(exitPrice - entryPrice) / int256(1e18);
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}
