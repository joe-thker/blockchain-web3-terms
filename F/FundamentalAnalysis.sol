// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FundamentalAnalysis {
    address public owner;

    struct FAReport {
        uint256 totalSupply;
        uint256 circulatingSupply;
        uint256 lockedSupply;
        uint256 treasuryBalance;
        uint256 activeAddresses;
        uint256 devTeamTokens;
        uint256 communityTokens;
        uint256 timestamp;
    }

    FAReport public latestReport;

    event FAUpdated(FAReport report);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// Submit an updated FA report
    function submitFAReport(
        uint256 totalSupply,
        uint256 circulatingSupply,
        uint256 lockedSupply,
        uint256 treasuryBalance,
        uint256 activeAddresses,
        uint256 devTeamTokens,
        uint256 communityTokens
    ) external onlyOwner {
        latestReport = FAReport({
            totalSupply: totalSupply,
            circulatingSupply: circulatingSupply,
            lockedSupply: lockedSupply,
            treasuryBalance: treasuryBalance,
            activeAddresses: activeAddresses,
            devTeamTokens: devTeamTokens,
            communityTokens: communityTokens,
            timestamp: block.timestamp
        });

        emit FAUpdated(latestReport);
    }

    /// Calculate % of tokens circulating
    function getCirculatingRatio() external view returns (uint256) {
        return (latestReport.circulatingSupply * 1e4) / latestReport.totalSupply;
    }

    /// Estimate treasury-to-supply ratio (how well-funded)
    function getTreasuryHealth() external view returns (uint256) {
        return (latestReport.treasuryBalance * 1e4) / latestReport.totalSupply;
    }

    /// Returns % of tokens controlled by team
    function getDevTokenRatio() external view returns (uint256) {
        return (latestReport.devTeamTokens * 1e4) / latestReport.totalSupply;
    }

    /// Returns % of tokens for community
    function getCommunityOwnershipRatio() external view returns (uint256) {
        return (latestReport.communityTokens * 1e4) / latestReport.totalSupply;
    }

    function getActiveAddressScore() external view returns (uint256) {
        // Simulated metric: active addresses per 1K tokens
        return latestReport.activeAddresses * 1e3 / latestReport.totalSupply;
    }
}
