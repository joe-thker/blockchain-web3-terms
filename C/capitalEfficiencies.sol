// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CapitalEfficiencyCalculator
/// @notice This contract calculates the capital efficiency ratio as a percentage.
/// Capital efficiency indicates the return generated per unit of capital invested.
contract CapitalEfficiencyCalculator {
    address public owner;
    uint256 public revenue;         // Total output or return generated
    uint256 public capitalInvested; // Total capital invested

    event ValuesUpdated(uint256 revenue, uint256 capitalInvested);
    event EfficiencyCalculated(uint256 efficiency);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Allows the owner to set or update revenue and capital invested.
    /// @param _revenue The total revenue or output generated.
    /// @param _capitalInvested The total capital that was invested.
    function updateValues(uint256 _revenue, uint256 _capitalInvested) external onlyOwner {
        require(_capitalInvested > 0, "Capital invested must be > 0");
        revenue = _revenue;
        capitalInvested = _capitalInvested;
        emit ValuesUpdated(_revenue, _capitalInvested);
    }

    /// @notice Calculates the capital efficiency as a percentage.
    /// @return efficiency The efficiency percentage (e.g., 150 means 150%).
    function calculateEfficiency() public view returns (uint256 efficiency) {
        // Efficiency (%) = (revenue / capitalInvested) * 100
        efficiency = (revenue * 100) / capitalInvested;
    }
}
