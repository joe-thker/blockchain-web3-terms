// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CreditRiskManager
/// @notice This contract manages collateral and debt for borrowers, tracking their collateralization ratio
/// as a measure of credit risk. Borrowers deposit an ERC20 token as collateral and can borrow funds (simulated as internal debt).
/// The minimum collateralization ratio is enforced to protect lenders.
contract CreditRiskManager is Ownable {
    using SafeERC20 for IERC20;

    // The collateral token (e.g., an ERC20 token)
    IERC20 public collateralToken;

    // Minimum collateralization ratio in basis points (e.g., 150% = 15000 bp; 10000 bp = 100%)
    uint256 public constant MIN_COLLATERALIZATION_BP = 15000;
    uint256 public constant BP_DIVISOR = 10000;

    struct BorrowerInfo {
        uint256 collateralAmount; // Total collateral deposited by the borrower
        uint256 debtAmount;       // Total debt borrowed by the borrower
    }

    mapping(address => BorrowerInfo) public borrowerData;

    event CollateralDeposited(address indexed borrower, uint256 amount);
    event CollateralWithdrawn(address indexed borrower, uint256 amount);
    event Borrowed(address indexed borrower, uint256 amount);
    event Repaid(address indexed borrower, uint256 amount);

    /// @notice Constructor sets the collateral token.
    /// @param _collateralToken The address of the ERC20 token used as collateral.
    constructor(IERC20 _collateralToken) {
        collateralToken = _collateralToken;
    }

    /// @notice Deposits collateral tokens into the contract.
    /// @param amount The amount of tokens to deposit.
    function depositCollateral(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        borrowerData[msg.sender].collateralAmount += amount;
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        emit CollateralDeposited(msg.sender, amount);
    }

    /// @notice Withdraws collateral tokens if the remaining collateral satisfies the minimum collateralization ratio.
    /// @param amount The amount of tokens to withdraw.
    function withdrawCollateral(uint256 amount) external {
        BorrowerInfo storage info = borrowerData[msg.sender];
        require(amount > 0, "Amount must be > 0");
        require(info.collateralAmount >= amount, "Insufficient collateral");

        // If there is outstanding debt, ensure that withdrawing collateral doesn't drop the collateralization ratio below the minimum.
        if (info.debtAmount > 0) {
            uint256 newCollateral = info.collateralAmount - amount;
            require(
                getCollateralizationRatio(newCollateral, info.debtAmount) >= MIN_COLLATERALIZATION_BP,
                "Withdrawal would violate collateralization requirements"
            );
        }

        info.collateralAmount -= amount;
        collateralToken.safeTransfer(msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    /// @notice Allows a borrower to borrow funds up to a limit based on their collateral.
    /// @param amount The amount to borrow.
    function borrow(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        BorrowerInfo storage info = borrowerData[msg.sender];
        require(info.collateralAmount > 0, "No collateral deposited");

        // Maximum borrowable amount = collateral / (minimum collateralization ratio / 10000)
        // For a 150% collateral ratio, maxBorrow = collateral * (10000 / 15000)
        uint256 maxBorrow = (info.collateralAmount * BP_DIVISOR) / MIN_COLLATERALIZATION_BP;
        require(info.debtAmount + amount <= maxBorrow, "Exceeds borrow limit based on collateral");

        info.debtAmount += amount;
        emit Borrowed(msg.sender, amount);
        // In a full implementation, this function would mint stablecoins or transfer funds to the borrower.
    }

    /// @notice Allows a borrower to repay their debt.
    /// @param amount The amount to repay.
    function repay(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        BorrowerInfo storage info = borrowerData[msg.sender];
        require(info.debtAmount >= amount, "Repay amount exceeds debt");

        info.debtAmount -= amount;
        emit Repaid(msg.sender, amount);
        // In a full implementation, the repaid funds would be burned or returned to the lending pool.
    }

    /// @notice Calculates the collateralization ratio in basis points.
    /// @param collateral The collateral amount.
    /// @param debt The debt amount.
    /// @return ratioBP The collateralization ratio in basis points.
    function getCollateralizationRatio(uint256 collateral, uint256 debt) public pure returns (uint256 ratioBP) {
        if (debt == 0) {
            return type(uint256).max; // Infinite collateralization if no debt.
        }
        // Ratio = (collateral / debt) * 10000 (in basis points)
        ratioBP = (collateral * BP_DIVISOR) / debt;
    }

    /// @notice Returns the current collateralization ratio for a borrower.
    /// @param borrower The address of the borrower.
    /// @return ratioBP The collateralization ratio in basis points.
    function getCollateralizationRatio(address borrower) external view returns (uint256 ratioBP) {
        BorrowerInfo memory info = borrowerData[borrower];
        ratioBP = getCollateralizationRatio(info.collateralAmount, info.debtAmount);
    }
}
