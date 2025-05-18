// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title YieldSensitivityLending - Lending with variable interest based on utilization
contract YieldSensitivityLending {
    uint256 public totalSupplied;
    uint256 public totalBorrowed;

    uint256 public constant KINK = 80e16;       // 80% utilization (in 1e18 scale)
    uint256 public constant BASE_RATE = 2e16;   // 2% APR
    uint256 public constant KINK_RATE = 10e16;  // 10% APR at kink
    uint256 public constant MAX_RATE = 40e16;   // 40% APR max

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;

    function deposit() external payable {
        require(msg.value > 0, "No ETH sent");
        deposits[msg.sender] += msg.value;
        totalSupplied += msg.value;
    }

    function borrow(uint256 amount) external {
        require(amount <= availableLiquidity(), "Not enough liquidity");
        borrows[msg.sender] += amount;
        totalBorrowed += amount;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");
    }

    function repay() external payable {
        require(msg.value > 0 && borrows[msg.sender] > 0, "Invalid repay");
        uint256 repayAmt = msg.value > borrows[msg.sender] ? borrows[msg.sender] : msg.value;
        borrows[msg.sender] -= repayAmt;
        totalBorrowed -= repayAmt;
    }

    function getUtilization() public view returns (uint256) {
        if (totalSupplied == 0) return 0;
        return (totalBorrowed * 1e18) / totalSupplied;
    }

    function currentBorrowRate() public view returns (uint256 apr) {
        uint256 util = getUtilization();
        if (util < KINK) {
            return BASE_RATE + (util * (KINK_RATE - BASE_RATE)) / KINK;
        } else {
            uint256 excessUtil = util - KINK;
            uint256 excessMax = 1e18 - KINK;
            return KINK_RATE + (excessUtil * (MAX_RATE - KINK_RATE)) / excessMax;
        }
    }

    function availableLiquidity() public view returns (uint256) {
        return totalSupplied - totalBorrowed;
    }
}
