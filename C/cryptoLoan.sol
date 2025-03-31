// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title CryptoLoan
/// @notice A simple crypto loan contract where borrowers deposit ETH as collateral and borrow stablecoins.
/// The loan is overcollateralized by a configurable collateralization ratio (e.g. 150%).
contract CryptoLoan is Ownable, ReentrancyGuard {
    // The stablecoin token used for loans.
    IERC20 public stableCoin;
    
    // Collateralization ratio as a percentage (e.g., 150 means 150% collateral is required).
    uint256 public collateralizationRatio;
    
    // Mapping from borrower address to collateral deposited (in wei).
    mapping(address => uint256) public collateralDeposits;
    
    // Mapping from borrower address to outstanding loan balance (in stablecoin units).
    mapping(address => uint256) public loanBalances;
    
    // --- Events ---
    event CollateralDeposited(address indexed borrower, uint256 amount);
    event LoanBorrowed(address indexed borrower, uint256 loanAmount);
    event LoanRepaid(address indexed borrower, uint256 amount);
    event CollateralWithdrawn(address indexed borrower, uint256 amount);
    event CollateralizationRatioUpdated(uint256 newRatio);

    /// @notice Constructor sets the stablecoin token address and the initial collateralization ratio.
    /// @param _stableCoin The address of the ERC20 stablecoin token.
    /// @param _collateralizationRatio The initial collateralization ratio (percentage, e.g. 150 for 150%).
    constructor(IERC20 _stableCoin, uint256 _collateralizationRatio) Ownable(msg.sender) {
        require(address(_stableCoin) != address(0), "Invalid stablecoin address");
        require(_collateralizationRatio >= 100, "Collateralization ratio must be >= 100");
        stableCoin = _stableCoin;
        collateralizationRatio = _collateralizationRatio;
    }
    
    /// @notice Allows the owner to update the collateralization ratio.
    /// @param newRatio The new collateralization ratio (percentage).
    function updateCollateralizationRatio(uint256 newRatio) external onlyOwner {
        require(newRatio >= 100, "Collateralization ratio must be >= 100");
        collateralizationRatio = newRatio;
        emit CollateralizationRatioUpdated(newRatio);
    }
    
    /// @notice Deposit ETH as collateral.
    function depositCollateral() external payable nonReentrant {
        require(msg.value > 0, "Must deposit > 0");
        collateralDeposits[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }
    
    /// @notice Borrow stablecoins against deposited collateral.
    /// @param loanAmount The amount of stablecoin to borrow.
    /// @dev For simplicity, we assume 1 ETH = 1 stablecoin in value.
    function borrow(uint256 loanAmount) external nonReentrant {
        require(loanAmount > 0, "Loan amount must be > 0");
        
        // Calculate required collateral for the new loan:
        // requiredCollateral = (loanBalance (existing + new) * collateralizationRatio) / 100.
        uint256 requiredCollateral = ((loanBalances[msg.sender] + loanAmount) * collateralizationRatio) / 100;
        uint256 availableCollateral = collateralDeposits[msg.sender];
        require(requiredCollateral <= availableCollateral, "Insufficient collateral");
        
        // Increase borrower's loan balance.
        loanBalances[msg.sender] += loanAmount;
        
        // Transfer stablecoin to borrower.
        require(stableCoin.transfer(msg.sender, loanAmount), "Stablecoin transfer failed");
        emit LoanBorrowed(msg.sender, loanAmount);
    }
    
    /// @notice Repay part or all of the outstanding loan.
    /// @param amount The amount of stablecoin to repay.
    function repayLoan(uint256 amount) external nonReentrant {
        require(amount > 0, "Repay amount must be > 0");
        uint256 currentLoan = loanBalances[msg.sender];
        require(currentLoan >= amount, "Repay amount exceeds loan balance");
        
        // Borrower must approve the stablecoin transfer before calling repayLoan.
        require(stableCoin.transferFrom(msg.sender, address(this), amount), "Stablecoin transfer failed");
        
        loanBalances[msg.sender] -= amount;
        emit LoanRepaid(msg.sender, amount);
    }
    
    /// @notice Withdraw collateral after fully repaying the loan.
    /// @param amount The amount of collateral (in wei) to withdraw.
    function withdrawCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdraw amount must be > 0");
        require(loanBalances[msg.sender] == 0, "Loan not fully repaid");
        require(collateralDeposits[msg.sender] >= amount, "Insufficient collateral");
        
        collateralDeposits[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }
    
    /// @notice Fallback function to receive ETH.
    receive() external payable {
        collateralDeposits[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }
}
