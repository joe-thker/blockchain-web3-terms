// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FA Treasury Health Tracker
/// @notice Evaluates on-chain treasury strength and runway

contract FATreasuryHealth {
    address public owner;

    struct TreasuryReport {
        uint256 treasuryBalance;     // e.g., in stablecoins
        uint256 totalSupply;         // total tokens ever minted
        uint256 circulatingSupply;   // tokens not locked or vested
        uint256 protocolExpensesPerMonth; // projected expenses
        uint256 updatedAt;
    }

    TreasuryReport public report;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function submitTreasuryData(
        uint256 treasuryBalance,
        uint256 totalSupply,
        uint256 circulatingSupply,
        uint256 monthlyExpenses
    ) external onlyOwner {
        report = TreasuryReport({
            treasuryBalance: treasuryBalance,
            totalSupply: totalSupply,
            circulatingSupply: circulatingSupply,
            protocolExpensesPerMonth: monthlyExpenses,
            updatedAt: block.timestamp
        });
    }

    function getTreasuryToSupplyRatio() external view returns (uint256) {
        return (report.treasuryBalance * 1e4) / report.totalSupply; // basis points
    }

    function getRunwayMonths() external view returns (uint256) {
        if (report.protocolExpensesPerMonth == 0) return type(uint256).max;
        return report.treasuryBalance / report.protocolExpensesPerMonth;
    }

    function getCirculatingValuePerToken() external view returns (uint256) {
        if (report.circulatingSupply == 0) return 0;
        return report.treasuryBalance / report.circulatingSupply;
    }
}
