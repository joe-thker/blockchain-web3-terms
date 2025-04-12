// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FA Token Distribution Analyzer
/// @notice Records supply breakdown and computes distribution health

contract FATokenDistribution {
    address public owner;

    struct Distribution {
        uint256 totalSupply;
        uint256 teamTokens;
        uint256 communityTokens;
        uint256 investorTokens;
        uint256 circulatingSupply;
    }

    Distribution public data;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function submitDistribution(
        uint256 totalSupply,
        uint256 teamTokens,
        uint256 communityTokens,
        uint256 investorTokens,
        uint256 circulatingSupply
    ) external onlyOwner {
        require(totalSupply >= teamTokens + communityTokens + investorTokens, "Overallocated");
        data = Distribution(totalSupply, teamTokens, communityTokens, investorTokens, circulatingSupply);
    }

    function getTeamRatio() public view returns (uint256) {
        return (data.teamTokens * 1e4) / data.totalSupply; // basis points
    }

    function getCommunityRatio() public view returns (uint256) {
        return (data.communityTokens * 1e4) / data.totalSupply;
    }

    function getInvestorRatio() public view returns (uint256) {
        return (data.investorTokens * 1e4) / data.totalSupply;
    }

    function getCirculatingRatio() public view returns (uint256) {
        return (data.circulatingSupply * 1e4) / data.totalSupply;
    }
}
