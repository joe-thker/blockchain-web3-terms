// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Leverage Types
/// @notice Demonstrates different leverage mechanisms in Solidity-based trading

/// 1. Fixed Leverage Contract
contract FixedLeverage {
    uint256 public constant LEVERAGE = 5; // 5x

    function getLeverageAmount(uint256 margin) external pure returns (uint256) {
        return margin * LEVERAGE;
    }
}

/// 2. User-Defined Leverage Contract
contract VariableLeverage {
    mapping(address => uint256) public leverageLevels;

    function setLeverage(uint256 level) external {
        require(level >= 1 && level <= 10, "Leverage out of range");
        leverageLevels[msg.sender] = level;
    }

    function calculateSize(uint256 margin) external view returns (uint256) {
        return margin * leverageLevels[msg.sender];
    }
}

/// 3. Dynamic Risk-Based Leverage
contract RiskLeverage {
    mapping(address => uint8) public userRiskTier; // 1 (low risk) to 5 (high risk)

    function setRiskTier(uint8 tier) external {
        require(tier >= 1 && tier <= 5, "Invalid tier");
        userRiskTier[msg.sender] = tier;
    }

    function getLeverage(uint256 margin) external view returns (uint256) {
        uint8 tier = userRiskTier[msg.sender];
        uint256 multiplier = 6 - tier; // Tier 1 => 5x, Tier 5 => 1x
        return margin * multiplier;
    }
}

/// 4. Oracle-Linked Leverage Contract (Simulated)
contract OracleLeverage {
    mapping(address => uint256) public lastPrice;

    function updateOracle(uint256 price) external {
        lastPrice[msg.sender] = price;
    }

    function getLeverage(uint256 margin) external view returns (uint256) {
        uint256 price = lastPrice[msg.sender];
        require(price > 0, "Price not set");
        uint256 factor = price < 1000 ? 3 : 1; // riskier under 1k
        return margin * factor;
    }
}

/// 5. Collateral-Weighted Leverage
contract CollateralWeightedLeverage {
    mapping(address => uint256) public userCollateral;

    function depositCollateral() external payable {
        userCollateral[msg.sender] += msg.value;
    }

    function calculateLeverage(uint256 requested) external view returns (uint256) {
        uint256 collateral = userCollateral[msg.sender];
        require(collateral > 0, "No collateral");
        uint256 maxAllowed = collateral * 3; // 3x cap
        return requested <= maxAllowed ? requested : maxAllowed;
    }

    receive() external payable {}
}
