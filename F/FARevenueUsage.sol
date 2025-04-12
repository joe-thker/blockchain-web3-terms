// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FARevenueUsage {
    address public owner;

    uint256 public totalFeesCollected;
    uint256 public transactionsLogged;

    event FeeLogged(uint256 amount);
    event TransactionRecorded(address user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function logFee(uint256 amount) external onlyOwner {
        totalFeesCollected += amount;
        emit FeeLogged(amount);
    }

    function logTransaction(address user) external onlyOwner {
        transactionsLogged += 1;
        emit TransactionRecorded(user);
    }

    function getAverageFeePerTx() external view returns (uint256) {
        if (transactionsLogged == 0) return 0;
        return totalFeesCollected / transactionsLogged;
    }
}
