// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice ERC20 token representing collateral deposits for a specific underlying token.
contract CollateralToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {}

    /// @notice Mint collateral tokens; can only be called by the owner (CollateralManager).
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /// @notice Burn collateral tokens; can only be called by the owner (CollateralManager).
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}

/// @notice The CollateralManager contract manages collateral deposits, borrowings,
/// withdrawals, collateral tokens, and enforces a minimum collateralization ratio.
contract CollateralManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Allowed underlying ERC20 tokens for collateral.
    mapping(address => bool) public allowedTokens;
    // Collateral factor for each token in basis points (e.g., 7500 for 75%).
    mapping(address => uint256) public collateralFactors;
    // User collateral balances: user => underlying token => amount.
    mapping(address => mapping(address => uint256)) public collateralBalances;
    // User borrow balances: user => underlying token => borrowed amount.
    mapping(address => mapping(address => uint256)) public borrowBalances;
    // Mapping from underlying token to its associated collateral token contract.
    mapping(address => CollateralToken) public collateralTokenContracts;

    // Minimum collateralization ratio (in basis points). E.g., 15000 = 150%
    uint256 public minCollateralizationRatio = 15000;

    // --- Events ---
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralWithdrawn(address indexed user, address indexed token, uint256 amount);
    event AllowedTokenAdded(address indexed token);
    event AllowedTokenRemoved(address indexed token);
    event CollateralFactorUpdated(address indexed token, uint256 factor);
    event Borrowed(address indexed user, address indexed token, uint256 amount);
    event Repaid(address indexed user, address indexed token, uint256 amount);
    event CollateralTokenCreated(address indexed underlyingToken, address collateralToken);
    event MinCollateralizationRatioUpdated(uint256 newRatio);

    // --- Modifiers ---
    modifier onlyAllowedToken(address token) {
        require(allowedTokens[token], "Token not allowed");
        _;
    }

    /// @notice Constructor sets the deployer as the owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Owner can update the minimum collateralization ratio (in basis points).
    function setMinCollateralizationRatio(uint256 ratio) external onlyOwner {
        require(ratio >= 10000, "Collateralization ratio must be at least 100%");
        minCollateralizationRatio = ratio;
        emit MinCollateralizationRatioUpdated(ratio);
    }

    /// @notice Owner can add an ERC20 token to the allowed list.
    function addAllowedToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        allowedTokens[token] = true;
        emit AllowedTokenAdded(token);
    }

    /// @notice Owner can remove an ERC20 token from the allowed list.
    function removeAllowedToken(address token) external onlyOwner {
        require(allowedTokens[token], "Token not allowed");
        allowedTokens[token] = false;
        emit AllowedTokenRemoved(token);
    }

    /// @notice Owner can set the collateral factor for an allowed token.
    function setCollateralFactor(address token, uint256 factor)
        external
        onlyOwner
        onlyAllowedToken(token)
    {
        require(factor <= 10000, "Factor must be <= 10000");
        collateralFactors[token] = factor;
        emit CollateralFactorUpdated(token, factor);
    }

    /// @notice Owner can create a collateral token for an allowed underlying token.
    function createCollateralToken(
        address token,
        string memory name,
        string memory symbol
    )
        external
        onlyOwner
        onlyAllowedToken(token)
    {
        require(address(collateralTokenContracts[token]) == address(0), "Collateral token already exists");
        CollateralToken ct = new CollateralToken(name, symbol);
        // Transfer ownership of the collateral token to this contract so it can mint/burn tokens.
        ct.transferOwnership(address(this));
        collateralTokenContracts[token] = ct;
        emit CollateralTokenCreated(token, address(ct));
    }

    /// @notice Allows a user to deposit an allowed token as collateral.
    /// Mints corresponding collateral tokens if available.
    function depositCollateral(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        collateralBalances[msg.sender][token] += amount;
        emit CollateralDeposited(msg.sender, token, amount);

        if (address(collateralTokenContracts[token]) != address(0)) {
            collateralTokenContracts[token].mint(msg.sender, amount);
        }
    }

    /// @notice Allows a user to withdraw collateral while maintaining the minimum collateralization ratio.
    /// Burns corresponding collateral tokens if available.
    function withdrawCollateral(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        uint256 currentCollateral = collateralBalances[msg.sender][token];
        require(currentCollateral >= amount, "Insufficient collateral");

        uint256 newCollateralBalance = currentCollateral - amount;
        uint256 newEffectiveCollateral = newCollateralBalance * collateralFactors[token] / 10000;
        // Check collateralization if there's any borrow.
        if (borrowBalances[msg.sender][token] > 0) {
            require(
                newEffectiveCollateral * 10000 >= borrowBalances[msg.sender][token] * minCollateralizationRatio,
                "Withdrawal would undercollateralize position"
            );
        }

        collateralBalances[msg.sender][token] = newCollateralBalance;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, token, amount);

        if (address(collateralTokenContracts[token]) != address(0)) {
            collateralTokenContracts[token].burn(msg.sender, amount);
        }
    }

    /// @notice Allows a user to borrow tokens against their collateral while maintaining the minimum collateralization ratio.
    function borrowCollateral(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        uint256 effectiveCollateral = collateralBalances[msg.sender][token] * collateralFactors[token] / 10000;
        uint256 newBorrowBalance = borrowBalances[msg.sender][token] + amount;
        require(
            effectiveCollateral * 10000 >= newBorrowBalance * minCollateralizationRatio,
            "Insufficient collateral for borrow"
        );

        borrowBalances[msg.sender][token] = newBorrowBalance;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Borrowed(msg.sender, token, amount);
    }

    /// @notice Allows a user to repay borrowed tokens.
    function repayBorrow(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        uint256 borrowed = borrowBalances[msg.sender][token];
        require(borrowed >= amount, "Repay amount exceeds borrowed balance");

        borrowBalances[msg.sender][token] = borrowed - amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Repaid(msg.sender, token, amount);
    }

    /// @notice Returns the deposited collateral balance for a user and token.
    function getCollateralBalance(address user, address token)
        external
        view
        returns (uint256)
    {
        return collateralBalances[user][token];
    }

    /// @notice Computes the effective collateral for a user.
    function getEffectiveCollateral(address user, address token)
        public
        view
        returns (uint256)
    {
        return collateralBalances[user][token] * collateralFactors[token] / 10000;
    }

    /// @notice Computes the collateral margin: effective collateral minus borrowed amount.
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

    /// @notice Computes the collateralization ratio for a user.
    /// Returns the ratio in basis points (e.g., 15000 means 150%); if no borrow exists, returns max uint256.
    function getCollateralizationRatio(address user, address token)
        external
        view
        returns (uint256)
    {
        uint256 borrowed = borrowBalances[user][token];
        if (borrowed == 0) {
            return type(uint256).max; // Infinite collateralization if no borrow.
        }
        uint256 effectiveCollateral = getEffectiveCollateral(user, token);
        return effectiveCollateral * 10000 / borrowed;
    }
}
