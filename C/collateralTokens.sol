// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin libraries for security and token operations
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice ERC20 token representing collateral deposits for a specific underlying token.
contract CollateralToken is ERC20, Ownable {
    /// @notice Constructor passes the name and symbol to ERC20 and sets the initial owner.
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
/// withdrawals, and collateral tokens.
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

    // --- Events ---
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralWithdrawn(address indexed user, address indexed token, uint256 amount);
    event AllowedTokenAdded(address indexed token);
    event AllowedTokenRemoved(address indexed token);
    event CollateralFactorUpdated(address indexed token, uint256 factor);
    event Borrowed(address indexed user, address indexed token, uint256 amount);
    event Repaid(address indexed user, address indexed token, uint256 amount);
    event CollateralTokenCreated(address indexed underlyingToken, address collateralToken);

    // --- Modifiers ---
    modifier onlyAllowedToken(address token) {
        require(allowedTokens[token], "Token not allowed");
        _;
    }

    /// @notice Constructor sets the deployer as the owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Owner can add an ERC20 token to the allowed list.
    /// @param token The address of the ERC20 token to allow.
    function addAllowedToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        allowedTokens[token] = true;
        emit AllowedTokenAdded(token);
    }

    /// @notice Owner can remove an ERC20 token from the allowed list.
    /// @param token The address of the ERC20 token to remove.
    function removeAllowedToken(address token) external onlyOwner {
        require(allowedTokens[token], "Token not allowed");
        allowedTokens[token] = false;
        emit AllowedTokenRemoved(token);
    }

    /// @notice Owner can set the collateral factor for an allowed token.
    /// @param token The address of the ERC20 token.
    /// @param factor The collateral factor in basis points (max 10000 equals 100%).
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
    /// @param token The underlying ERC20 token address.
    /// @param name The name for the collateral token.
    /// @param symbol The symbol for the collateral token.
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
    /// @param token The underlying ERC20 token to deposit.
    /// @param amount The deposit amount.
    function depositCollateral(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        collateralBalances[msg.sender][token] += amount;
        emit CollateralDeposited(msg.sender, token, amount);

        // Mint collateral tokens representing the deposit if a collateral token exists.
        if (address(collateralTokenContracts[token]) != address(0)) {
            collateralTokenContracts[token].mint(msg.sender, amount);
        }
    }

    /// @notice Allows a user to withdraw collateral, ensuring remaining deposits cover borrowings.
    /// Burns corresponding collateral tokens if available.
    /// @param token The underlying ERC20 token to withdraw.
    /// @param amount The withdrawal amount.
    function withdrawCollateral(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        uint256 currentCollateral = collateralBalances[msg.sender][token];
        require(currentCollateral >= amount, "Insufficient collateral");

        uint256 newCollateralBalance = currentCollateral - amount;
        uint256 effectiveCollateral = newCollateralBalance * collateralFactors[token] / 10000;
        require(effectiveCollateral >= borrowBalances[msg.sender][token], "Withdrawal would undercollateralize position");

        collateralBalances[msg.sender][token] = newCollateralBalance;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, token, amount);

        // Burn the collateral tokens representing the withdrawn amount.
        if (address(collateralTokenContracts[token]) != address(0)) {
            collateralTokenContracts[token].burn(msg.sender, amount);
        }
    }

    /// @notice Allows a user to borrow tokens against their collateral.
    /// @param token The underlying ERC20 token to borrow.
    /// @param amount The amount to borrow.
    function borrowCollateral(address token, uint256 amount)
        external
        nonReentrant
        onlyAllowedToken(token)
    {
        require(amount > 0, "Amount must be > 0");
        uint256 effectiveCollateral = collateralBalances[msg.sender][token] * collateralFactors[token] / 10000;
        uint256 newBorrowBalance = borrowBalances[msg.sender][token] + amount;
        require(newBorrowBalance <= effectiveCollateral, "Insufficient collateral for borrow");

        borrowBalances[msg.sender][token] = newBorrowBalance;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Borrowed(msg.sender, token, amount);
    }

    /// @notice Allows a user to repay borrowed tokens.
    /// @param token The underlying ERC20 token to repay.
    /// @param amount The repayment amount.
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

    /// @notice Computes the effective collateral for a user (deposit × collateral factor).
    function getEffectiveCollateral(address user, address token)
        public
        view
        returns (uint256)
    {
        return collateralBalances[user][token] * collateralFactors[token] / 10000;
    }

    /// @notice Computes the collateral margin: effective collateral minus borrowed amount.
    /// A negative margin indicates an undercollateralized position.
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
