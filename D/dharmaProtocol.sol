// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Minimal interface for an ERC20 token.
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title DharmaProtocol
/// @notice A simplified, dynamic, and optimized lending/borrowing contract (inspired by Dharma).
/// Users (lenders) deposit stable tokens, which borrowers can borrow by locking collateral tokens.
contract DharmaProtocol is Ownable, ReentrancyGuard {
    /// @notice The ERC20 token used for lending and borrowing (e.g., stablecoin).
    IERC20 public stableToken;

    /// @notice The ERC20 token used as collateral (e.g. WETH).
    IERC20 public collateralToken;

    /// @notice The interest rate (annualized) in basis points. (E.g., 500 = 5%.)
    uint256 public interestRateBps;
    /// @notice Collateralization ratio in basis points (e.g., 15000 = 150%).
    uint256 public collateralRatioBps;

    /// @notice Mapping of each lender’s deposit balance in stableToken.
    mapping(address => uint256) public lenderBalances;
    /// @notice Total stable tokens deposited by all lenders.
    uint256 public totalLenderDeposits;

    // --- Data Structures for Loans ---

    /// @notice Structure representing a borrower’s loan.
    struct Loan {
        uint256 id;
        address borrower;
        uint256 stableBorrowed;
        uint256 collateralLocked;
        bool active;
    }

    /// @notice Incrementing ID counter for each loan.
    uint256 public nextLoanId;
    /// @notice Mapping of loan ID to Loan info.
    mapping(uint256 => Loan) public loans;
    /// @notice Mapping from borrower to their active loan ID (0 if none).
    mapping(address => uint256) public userLoanId;

    // --- Events ---
    event ParametersUpdated(uint256 newInterestRateBps, uint256 newCollateralRatioBps);
    event StableTokenUpdated(address indexed newStableToken);
    event CollateralTokenUpdated(address indexed newCollateralToken);
    event Deposited(address indexed lender, uint256 amount);
    event Withdrawn(address indexed lender, uint256 amount);

    event LoanOpened(uint256 indexed loanId, address indexed borrower, uint256 stableBorrowed, uint256 collateralLocked);
    event LoanRepaid(uint256 indexed loanId, address indexed borrower, uint256 stablePaid);
    event CollateralReturned(uint256 indexed loanId, address indexed borrower, uint256 collateralReturned);

    /// @notice Constructor sets the tokens (stable and collateral) and some initial parameters.
    /// @param _stableToken The stablecoin address used for lending/borrowing.
    /// @param _collateralToken The collateral token address.
    /// @param _interestRateBps The interest rate in basis points.
    /// @param _collateralRatioBps The collateral ratio in basis points (e.g., 15000 = 150%).
    constructor(
        address _stableToken,
        address _collateralToken,
        uint256 _interestRateBps,
        uint256 _collateralRatioBps
    ) Ownable(msg.sender) {
        require(_stableToken != address(0), "Invalid stable token address");
        require(_collateralToken != address(0), "Invalid collateral token address");
        require(_collateralRatioBps >= 10000, "Collateral ratio must be >= 100%");

        stableToken = IERC20(_stableToken);
        collateralToken = IERC20(_collateralToken);
        interestRateBps = _interestRateBps;
        collateralRatioBps = _collateralRatioBps;
    }

    // --- Admin Functions ---

    /// @notice Updates the interest rate and collateral ratio. Only owner can call.
    /// @param newInterestRateBps New interest rate in basis points.
    /// @param newCollateralRatioBps New collateral ratio in basis points.
    function updateParameters(uint256 newInterestRateBps, uint256 newCollateralRatioBps) external onlyOwner {
        interestRateBps = newInterestRateBps;
        require(newCollateralRatioBps >= 10000, "Collateral ratio must be >= 100%");
        collateralRatioBps = newCollateralRatioBps;
        emit ParametersUpdated(newInterestRateBps, newCollateralRatioBps);
    }

    /// @notice Updates the stable token address used for lending/borrowing.
    /// @param newToken The new stable token address.
    function updateStableToken(address newToken) external onlyOwner {
        require(newToken != address(0), "Invalid token address");
        stableToken = IERC20(newToken);
        emit StableTokenUpdated(newToken);
    }

    /// @notice Updates the collateral token address used as collateral.
    /// @param newToken The new collateral token address.
    function updateCollateralToken(address newToken) external onlyOwner {
        require(newToken != address(0), "Invalid token address");
        collateralToken = IERC20(newToken);
        emit CollateralTokenUpdated(newToken);
    }

    // --- Lender Functions ---

    /// @notice Lenders deposit stable tokens to earn interest (not implemented in detail here).
    /// @param amount The amount of stable tokens to deposit.
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be > 0");
        bool success = stableToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Stable token transfer failed");

        lenderBalances[msg.sender] += amount;
        totalLenderDeposits += amount;

        emit Deposited(msg.sender, amount);
    }

    /// @notice Lenders withdraw their deposited stable tokens. No interest logic in this simplified version.
    /// @param amount The amount of stable tokens to withdraw.
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdraw amount must be > 0");
        require(lenderBalances[msg.sender] >= amount, "Insufficient lender balance");

        lenderBalances[msg.sender] -= amount;
        totalLenderDeposits -= amount;

        bool success = stableToken.transfer(msg.sender, amount);
        require(success, "Stable token transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // --- Borrower Functions ---

    /// @notice A borrower opens a loan by locking collateral and receiving stable tokens from the pool.
    /// @param stableAmount The amount of stable tokens to borrow.
    /// @param collateralAmount The amount of collateral tokens to lock.
    function openLoan(uint256 stableAmount, uint256 collateralAmount) external nonReentrant {
        require(userLoanId[msg.sender] == 0, "Existing loan active");
        require(stableAmount > 0 && collateralAmount > 0, "Invalid amounts");

        // Check if the system has enough stable tokens to lend
        require(stableAmount <= totalLenderDeposits, "Insufficient pool liquidity");

        // Collateral ratio check (simple 1:1 token value assumption).
        // e.g. if ratio=15000 => 150%, then collateral >= stable * 1.5
        require(collateralAmount * 10000 >= stableAmount * collateralRatioBps, "Insufficient collateral for ratio");

        // Transfer collateral from borrower to contract
        bool collateralSuccess = collateralToken.transferFrom(msg.sender, address(this), collateralAmount);
        require(collateralSuccess, "Collateral transfer failed");

        // Record the loan
        uint256 loanId = ++nextLoanId;
        loans[loanId] = Loan({
            id: loanId,
            borrower: msg.sender,
            stableBorrowed: stableAmount,
            collateralLocked: collateralAmount,
            active: true
        });
        userLoanId[msg.sender] = loanId;

        // Transfer stable tokens to borrower
        bool stableSuccess = stableToken.transfer(msg.sender, stableAmount);
        require(stableSuccess, "Stable token transfer failed");

        emit LoanOpened(loanId, msg.sender, stableAmount, collateralAmount);
    }

    /// @notice Repay the borrowed stable tokens. The contract returns the locked collateral to the borrower.
    /// @param loanId The ID of the loan to repay.
    function repayLoan(uint256 loanId) external nonReentrant {
        Loan storage ln = loans[loanId];
        require(ln.active, "Loan not active");
        require(ln.borrower == msg.sender, "Not the borrower");

        uint256 owed = ln.stableBorrowed;
        ln.active = false;
        userLoanId[msg.sender] = 0;

        // Transfer stable from borrower back to contract
        bool repaySuccess = stableToken.transferFrom(msg.sender, address(this), owed);
        require(repaySuccess, "Repay transfer failed");

        // Return the collateral to the borrower
        uint256 locked = ln.collateralLocked;
        ln.collateralLocked = 0;
        bool collateralReturn = collateralToken.transfer(msg.sender, locked);
        require(collateralReturn, "Collateral return failed");

        emit LoanRepaid(loanId, msg.sender, owed);
        emit CollateralReturned(loanId, msg.sender, locked);
    }

    // --- View Functions ---

    /// @notice Retrieves loan details by ID.
    /// @param loanId The loan ID.
    /// @return A Loan struct containing details.
    function getLoan(uint256 loanId) external view returns (Loan memory) {
        return loans[loanId];
    }

    /// @notice Returns the active loan ID for a specific borrower (0 if none).
    /// @param borrower The borrower's address.
    /// @return The loan ID, or 0 if no active loan.
    function getActiveLoanId(address borrower) external view returns (uint256) {
        return userLoanId[borrower];
    }
}
