// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract LongPositionManager {
    IERC20 public collateralToken; // e.g., USDC
    uint256 public ethPrice = 2000e18; // Simulated oracle price

    struct Position {
        uint256 collateral;
        uint256 size;       // in ETH (1e18 precision)
        uint256 entryPrice; // snapshot price
        bool open;
    }

    mapping(address => Position) public positions;
    uint256 public liquidationThreshold = 80; // Liquidate at 80% loss
    uint256 public leverage = 5; // 5x leverage

    constructor(address _collateral) {
        collateralToken = IERC20(_collateral);
    }

    function openLong(uint256 collateralAmount) external {
        require(!positions[msg.sender].open, "Already open");

        require(collateralToken.transferFrom(msg.sender, address(this), collateralAmount), "Transfer failed");

        uint256 positionSize = (collateralAmount * leverage * 1e18) / ethPrice;

        positions[msg.sender] = Position({
            collateral: collateralAmount,
            size: positionSize,
            entryPrice: ethPrice,
            open: true
        });
    }

    function getPnL(address user) public view returns (int256 pnl) {
        Position memory p = positions[user];
        if (!p.open) return 0;

        uint256 currentValue = (p.size * ethPrice) / 1e18;
        pnl = int256(currentValue) - int256(p.collateral * leverage);
    }

    function closeLong() external {
        Position memory p = positions[msg.sender];
        require(p.open, "No position");

        int256 pnl = getPnL(msg.sender);
        uint256 payout;

        if (pnl < 0 && uint256(-pnl) >= p.collateral) {
            payout = 0; // liquidated
        } else {
            payout = p.collateral + uint256(pnl);
        }

        delete positions[msg.sender];
        collateralToken.transfer(msg.sender, payout);
    }

    function liquidate(address user) external {
        Position memory p = positions[user];
        require(p.open, "No position");

        int256 pnl = getPnL(user);
        uint256 loss = pnl < 0 ? uint256(-pnl) : 0;
        if (loss * 100 / p.collateral >= liquidationThreshold) {
            delete positions[user];
            // Collateral stays in contract (bad debt or auction logic here)
        } else {
            revert("Not eligible for liquidation");
        }
    }
}
