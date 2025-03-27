// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice CollateralizedStableCoin is an ERC20 token representing the stable coin.
/// Users deposit a collateral ERC20 token and then mint stable coins up to a safe collateralization ratio.
/// They can later burn stable coins (repay debt) and withdraw collateral as long as the collateralization remains sufficient.
contract CollateralizedStableCoin is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // The collateral token backing the stable coin (e.g., an ERC20 token).
    IERC20 public immutable collateralToken;
    
    // Mapping to track each user's deposited collateral and incurred debt (stable coin minted).
    mapping(address => uint256) public collateralBalance;
    mapping(address => uint256) public debtBalance;
    
    // Required collateralization ratio in basis points.
    // For example, a value of 15000 means the collateral must be at least 150% of the debt.
    uint256 public collateralizationRatio;
    
    // --- Events ---
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event StableCoinMinted(address indexed user, uint256 amount);
    event StableCoinBurned(address indexed user, uint256 amount);
    
    /// @notice Constructor sets the collateral token, initial collateralization ratio, and stable coin details.
    /// @param _collateralToken Address of the collateral ERC20 token.
    /// @param _collateralizationRatio Required collateralization ratio in basis points (must be at least 10000 = 100%).
    /// @param name Name of the stable coin.
    /// @param symbol Symbol of the stable coin.
    constructor(
        address _collateralToken,
        uint256 _collateralizationRatio, 
        string memory name, 
        string memory symbol
    )
        ERC20(name, symbol)
        Ownable(msg.sender)
    {
        require(_collateralToken != address(0), "Invalid collateral token address");
        require(_collateralizationRatio >= 10000, "Collateralization ratio must be at least 100%");
        collateralToken = IERC20(_collateralToken);
        collateralizationRatio = _collateralizationRatio;
    }
    
    /// @notice Deposit collateral tokens into the system.
    /// The user’s collateral balance increases.
    function depositCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        collateralBalance[msg.sender] += amount;
        emit CollateralDeposited(msg.sender, amount);
    }
    
    /// @notice Withdraw collateral tokens from the system.
    /// Withdrawal is allowed only if the remaining collateral still meets the collateralization ratio for the user's debt.
    function withdrawCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(collateralBalance[msg.sender] >= amount, "Insufficient collateral balance");
        
        uint256 newCollateral = collateralBalance[msg.sender] - amount;
        require(_isCollateralSufficient(msg.sender, newCollateral, debtBalance[msg.sender]), "Withdrawal would breach collateralization ratio");
        
        collateralBalance[msg.sender] = newCollateral;
        collateralToken.safeTransfer(msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }
    
    /// @notice Mint stable coins against deposited collateral.
    /// Increases the user's debt balance and mints new stable coin tokens.
    function mintStableCoin(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        uint256 newDebt = debtBalance[msg.sender] + amount;
        require(_isCollateralSufficient(msg.sender, collateralBalance[msg.sender], newDebt), "Insufficient collateral to mint that amount");
        
        debtBalance[msg.sender] = newDebt;
        _mint(msg.sender, amount);
        emit StableCoinMinted(msg.sender, amount);
    }
    
    /// @notice Burn stable coins (repay debt) to reduce the user's debt balance.
    function burnStableCoin(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(debtBalance[msg.sender] >= amount, "Amount exceeds debt");
        
        debtBalance[msg.sender] -= amount;
        _burn(msg.sender, amount);
        emit StableCoinBurned(msg.sender, amount);
    }
    
    /// @notice Internal helper to verify that a given collateral and debt satisfy the required collateralization ratio.
    /// Assumes a 1:1 price relationship between collateral and stable coin.
    /// @return True if collateral * 10000 >= debt * collateralizationRatio.
    function _isCollateralSufficient(address user, uint256 collateralAmt, uint256 debtAmt) internal view returns (bool) {
        // If the user has no debt, collateral is sufficient.
        if (debtAmt == 0) {
            return true;
        }
        return (collateralAmt * 10000) >= (debtAmt * collateralizationRatio);
    }
    
    /// @notice Returns the current collateralization ratio of a user in basis points.
    /// If the user has no debt, returns the maximum uint256.
    function getUserCollateralizationRatio(address user) external view returns (uint256) {
        uint256 debt = debtBalance[user];
        if (debt == 0) {
            return type(uint256).max;
        }
        return (collateralBalance[user] * 10000) / debt;
    }
    
    /// @notice Owner can update the required collateralization ratio.
    function updateCollateralizationRatio(uint256 newRatio) external onlyOwner {
        require(newRatio >= 10000, "Collateralization ratio must be at least 100%");
        collateralizationRatio = newRatio;
    }
}
