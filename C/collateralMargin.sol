// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin libraries for security and token operations
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CollateralManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Mapping to keep track of allowed ERC20 tokens for collateral
    mapping(address => bool) public allowedTokens;
    // Mapping to store collateral factors for each token in basis points (e.g., 7500 for 75%)
    mapping(address => uint256) public collateralFactors;
    // Mapping to track user collateral balances: user => token => amount
    mapping(address => mapping(address => uint256)) public collateralBalances;
    // Mapping to track user borrow balances: user => token => borrowed amount
    mapping(address => mapping(address => uint256)) public borrowBalances;

    // Events for transparency and off-chain tracking
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralWithdrawn(address indexed user, address indexed token, uint256 amount);
    event AllowedTokenAdded(address indexed token);
    event AllowedTokenRemoved(address indexed token);
    event CollateralFactorUpdated(address indexed token, uint256 factor);
    event Borrowed(address indexed user, address indexed token, uint256 amount);
    event Repaid(address indexed user, address indexed token, uint256 amount);

    // Modifier to ensure the token is allowed for collateral operations
    modifier onlyAllowedToken(address token) {
        require(allowedTokens[token], "Token not allowed");
        _;
    }

    /// @notice Constructor initializes the contract owner
    constructor() Ownable(msg.sender) {}

    /// @notice Owner can add an ERC20 token to the allowed list
    /// @param token The address of the ERC20 token to allow
    function addAllowedToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        allowedTokens[token] = true;
        emit AllowedTokenAdded(token);
    }

    /// @notice Owner can remove an ERC20 token from the allowed list
    /// @param token The address of the ERC20 token to remove
    function removeAllowedToken(address token) external onlyOwner {
        require(allowedTokens[token], "Token not allowed");
        allowedTokens[token] = false;
        emit AllowedTokenRemoved(token);
    }

    /// @notice Owner can set the collateral factor for an allowed token
    /// @param token The address of the ERC20 token
    /// @param factor The collateral factor in basis points (max 10000, which equals 100%)
    function setCollateralFactor(address token, uint256 factor) external onlyOwner onlyAllowedToken(token) {
        require(factor <= 10000, "Factor must be <= 10000");
        collateralFactors[token] = factor;
        emit CollateralFactorUpdated(token, factor);
    }

    /// @notice Allows a user to deposit a specified amount of an allowed token as collateral
    /// @param token The address of the ERC20 token to deposit
    /// @param amount The amount of tokens to deposit
    function depositCollateral(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        // Transfer tokens from the user to this contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        collateralBalances[msg.sender][token] += amount;
        emit CollateralDeposited(msg.sender, token, amount);
    }

    /// @notice Allows a user to withdraw a specified amount of their collateral,
    /// ensuring the remaining effective collateral covers any borrowings.
    /// @param token The address of the ERC20 token to withdraw
    /// @param amount The amount of tokens to withdraw
    function withdrawCollateral(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        uint256 currentCollateral = collateralBalances[msg.sender][token];
        require(currentCollateral >= amount, "Insufficient collateral");

        // Calculate new collateral balance after withdrawal
        uint256 newCollateralBalance = currentCollateral - amount;
        // Compute effective collateral after withdrawal
        uint256 effectiveCollateral = newCollateralBalance * collateralFactors[token] / 10000;
        // Ensure that the remaining collateral covers the borrowed amount
        require(effectiveCollateral >= borrowBalances[msg.sender][token], "Withdrawal would undercollateralize position");

        collateralBalances[msg.sender][token] = newCollateralBalance;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, token, amount);
    }

    /// @notice Allows a user to borrow tokens against their collateral.
    /// The new borrow balance cannot exceed the user's effective collateral.
    /// @param token The address of the ERC20 token to borrow
    /// @param amount The amount of tokens to borrow
    function borrowCollateral(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        // Compute user's effective collateral value
        uint256 effectiveCollateral = collateralBalances[msg.sender][token] * collateralFactors[token] / 10000;
        uint256 newBorrowBalance = borrowBalances[msg.sender][token] + amount;
        // Ensure that the new borrow does not exceed effective collateral
        require(newBorrowBalance <= effectiveCollateral, "Insufficient collateral for borrow");

        borrowBalances[msg.sender][token] = newBorrowBalance;
        // Transfer the borrowed tokens to the user (assuming the contract holds sufficient liquidity)
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Borrowed(msg.sender, token, amount);
    }

    /// @notice Allows a user to repay their borrowed tokens.
    /// @param token The address of the ERC20 token to repay
    /// @param amount The amount of tokens to repay
    function repayBorrow(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        uint256 borrowed = borrowBalances[msg.sender][token];
        require(borrowed >= amount, "Repay amount exceeds borrowed balance");

        borrowBalances[msg.sender][token] = borrowed - amount;
        // Transfer tokens from the user to this contract as repayment
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Repaid(msg.sender, token, amount);
    }

    /// @notice Returns the collateral balance for a given user and token.
    /// @param user The address of the user
    /// @param token The address of the ERC20 token
    /// @return The amount of collateral the user has deposited for the token
    function getCollateralBalance(address user, address token)
        external
        view
        returns (uint256)
    {
        return collateralBalances[user][token];
    }

    /// @notice Computes the effective collateral for a user based on the collateral factor of the token.
    /// @param user The address of the user
    /// @param token The address of the ERC20 token
    /// @return The effective collateral value after applying the collateral factor
    function getEffectiveCollateral(address user, address token)
        public
        view
        returns (uint256)
    {
        return collateralBalances[user][token] * collateralFactors[token] / 10000;
    }

    /// @notice Computes the collateral margin for a user,
    /// defined as the effective collateral minus the borrowed amount.
    /// A negative margin indicates that the position is undercollateralized.
    /// @param user The address of the user
    /// @param token The address of the ERC20 token
    /// @return The collateral margin as a signed integer
    function getCollateralMargin(address user, address token)
        external
        view
        returns (int256)
    {
        uint256 effectiveCollateral = getEffectiveCollateral(user, token);
        uint256 borrowed = borrowBalances[user][token];
        if (effectiveCollateral >= borrowed) {
            return int256(effectiveCollateral - borrowed);
        } else {
            return -int256(borrowed - effectiveCollateral);
        }
    }
}
