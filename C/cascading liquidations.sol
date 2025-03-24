// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CascadingLiquidations {
    address public owner;
    // Price of the collateral asset (in an arbitrary unit, e.g., USD with 18 decimals)
    uint256 public price;
    // Required collateralization ratio (in percentage, e.g., 150 means 150%)
    uint256 public collateralizationThreshold;
    
    // An array to store the addresses of all position holders.
    address[] public positionHolders;

    struct Position {
        uint256 collateral; // Amount of collateral deposited
        uint256 debt;       // Amount borrowed
        bool exists;        // Flag indicating if the position exists
    }
    
    mapping(address => Position) public positions;
    
    event PositionOpened(address indexed user, uint256 collateral, uint256 debt);
    event PositionLiquidated(address indexed user);
    event PriceUpdated(uint256 newPrice);
    event CascadeLiquidation(uint256 liquidatedCount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }
    
    constructor(uint256 _initialPrice, uint256 _collateralizationThreshold) {
        owner = msg.sender;
        price = _initialPrice;
        collateralizationThreshold = _collateralizationThreshold;
    }
    
    /// @notice Opens a position by depositing collateral and borrowing funds.
    /// @param collateralAmount Amount of collateral deposited.
    /// @param debtAmount Amount of funds borrowed.
    function openPosition(uint256 collateralAmount, uint256 debtAmount) external {
        require(collateralAmount > 0 && debtAmount > 0, "Amounts must be > 0");
        require(!positions[msg.sender].exists, "Position already exists");
        positions[msg.sender] = Position({
            collateral: collateralAmount,
            debt: debtAmount,
            exists: true
        });
        positionHolders.push(msg.sender);
        emit PositionOpened(msg.sender, collateralAmount, debtAmount);
    }
    
    /// @notice Updates the price of the collateral asset.
    /// @param newPrice The new price.
    function updatePrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceUpdated(newPrice);
    }
    
    /// @notice Calculates the collateralization ratio of a position.
    /// @param user The address of the position holder.
    /// @return ratio The collateralization ratio in percentage.
    function getCollateralRatio(address user) public view returns (uint256 ratio) {
        Position memory pos = positions[user];
        if (pos.debt == 0) {
            return type(uint256).max;
        }
        // Ratio = (collateral * price * 100) / debt
        ratio = (pos.collateral * price * 100) / pos.debt;
    }
    
    /// @notice Liquidates a position if its collateralization ratio is below the threshold.
    /// @param user The address of the position to liquidate.
    /// @return liquidated True if the position was liquidated.
    function liquidatePosition(address user) public returns (bool liquidated) {
        Position storage pos = positions[user];
        require(pos.exists, "Position does not exist");
        uint256 ratio = getCollateralRatio(user);
        if (ratio < collateralizationThreshold) {
            delete positions[user];
            liquidated = true;
            emit PositionLiquidated(user);
        }
    }
    
    /// @notice Runs a cascading liquidation process that liquidates all undercollateralized positions.
    /// @return liquidatedCount The total number of positions liquidated.
    function cascadeLiquidations() external returns (uint256 liquidatedCount) {
        liquidatedCount = 0;
        bool liquidationOccurred = true;
        // Continue looping until no further liquidations occur.
        while (liquidationOccurred) {
            liquidationOccurred = false;
            for (uint256 i = 0; i < positionHolders.length; i++) {
                address user = positionHolders[i];
                if (positions[user].exists && getCollateralRatio(user) < collateralizationThreshold) {
                    liquidatePosition(user);
                    liquidatedCount++;
                    liquidationOccurred = true;
                }
            }
        }
        emit CascadeLiquidation(liquidatedCount);
    }
    
    /// @notice Returns the total number of positions.
    function getPositionCount() external view returns (uint256) {
        return positionHolders.length;
    }
}
