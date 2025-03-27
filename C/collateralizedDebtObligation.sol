// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Senior Tranche Token representing senior tranche investments in the CDO.
contract SeniorTrancheToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {}

    /// @notice Mint tokens; callable only by the owner (the CDO contract).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

/// @notice Junior Tranche Token representing junior tranche investments in the CDO.
contract JuniorTrancheToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {}

    /// @notice Mint tokens; callable only by the owner (the CDO contract).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

/// @notice Collateralized Debt Obligation (CDO) contract that securitizes a pool of funds into two tranches.
contract CollateralizedDebtObligation is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Underlying token used for investments (e.g., a stablecoin).
    IERC20 public immutable underlying;

    // Tranche tokens.
    SeniorTrancheToken public seniorToken;
    JuniorTrancheToken public juniorToken;

    // Investment caps for each tranche.
    uint256 public seniorCap;
    uint256 public juniorCap;

    // Total invested amounts in each tranche.
    uint256 public totalSeniorInvested;
    uint256 public totalJuniorInvested;

    // Expected total debt to be repaid.
    uint256 public totalDebt;

    // CDO lifecycle states.
    enum State { Investment, Active, Repaid }
    State public state;

    // Track if an investor has redeemed their payout.
    mapping(address => bool) public redeemed;

    // --- Events ---
    event InvestedSenior(address indexed investor, uint256 amount);
    event InvestedJunior(address indexed investor, uint256 amount);
    event CDOActivated(uint256 totalDebt);
    event DebtRepaid(uint256 amount);
    event Redemption(address indexed investor, uint256 seniorPayout, uint256 juniorPayout);

    /// @notice Initializes the CDO with investment caps, expected debt, and creates tranche tokens.
    /// @param _underlying The address of the underlying ERC20 token.
    /// @param _seniorCap Maximum investment for the senior tranche.
    /// @param _juniorCap Maximum investment for the junior tranche.
    /// @param _totalDebt Expected total debt to be repaid.
    /// @param seniorName Name for the senior tranche token.
    /// @param seniorSymbol Symbol for the senior tranche token.
    /// @param juniorName Name for the junior tranche token.
    /// @param juniorSymbol Symbol for the junior tranche token.
    constructor(
        address _underlying,
        uint256 _seniorCap,
        uint256 _juniorCap,
        uint256 _totalDebt,
        string memory seniorName,
        string memory seniorSymbol,
        string memory juniorName,
        string memory juniorSymbol
    )
        Ownable(msg.sender)
    {
        require(_underlying != address(0), "Invalid underlying token address");
        underlying = IERC20(_underlying);
        seniorCap = _seniorCap;
        juniorCap = _juniorCap;
        totalDebt = _totalDebt;
        state = State.Investment;

        seniorToken = new SeniorTrancheToken(seniorName, seniorSymbol);
        seniorToken.transferOwnership(address(this));

        juniorToken = new JuniorTrancheToken(juniorName, juniorSymbol);
        juniorToken.transferOwnership(address(this));
    }

    /// @notice Investors can deposit underlying tokens to invest in the senior tranche.
    /// They receive senior tranche tokens equal to the invested amount.
    function investSenior(uint256 amount) external nonReentrant {
        require(state == State.Investment, "Not in investment phase");
        require(amount > 0, "Amount must be > 0");
        require(totalSeniorInvested + amount <= seniorCap, "Senior tranche cap exceeded");

        underlying.safeTransferFrom(msg.sender, address(this), amount);
        totalSeniorInvested += amount;
        seniorToken.mint(msg.sender, amount);

        emit InvestedSenior(msg.sender, amount);
    }

    /// @notice Investors can deposit underlying tokens to invest in the junior tranche.
    /// They receive junior tranche tokens equal to the invested amount.
    function investJunior(uint256 amount) external nonReentrant {
        require(state == State.Investment, "Not in investment phase");
        require(amount > 0, "Amount must be > 0");
        require(totalJuniorInvested + amount <= juniorCap, "Junior tranche cap exceeded");

        underlying.safeTransferFrom(msg.sender, address(this), amount);
        totalJuniorInvested += amount;
        juniorToken.mint(msg.sender, amount);

        emit InvestedJunior(msg.sender, amount);
    }

    /// @notice After the investment phase, the owner activates the CDO.
    /// This moves the CDO into the Active state.
    function activateCDO() external onlyOwner nonReentrant {
        require(state == State.Investment, "CDO already activated");
        state = State.Active;
        emit CDOActivated(totalDebt);
    }

    /// @notice The owner records the debt repayment by transferring funds to this contract.
    /// For simplicity, this example assumes a full repayment in a single transaction.
    function repayDebt(uint256 amount) external onlyOwner nonReentrant {
        require(state == State.Active, "CDO not active");
        require(amount > 0, "Amount must be > 0");
        underlying.safeTransferFrom(msg.sender, address(this), amount);
        state = State.Repaid;
        emit DebtRepaid(amount);
    }

    /// @notice Investors redeem their tranche tokens for their share of the repaid funds.
    /// The payout is distributed proportionally based on their investment.
    function redeem() external nonReentrant {
        require(state == State.Repaid, "Debt not repaid");
        require(!redeemed[msg.sender], "Already redeemed");

        uint256 investorSeniorBalance = seniorToken.balanceOf(msg.sender);
        uint256 investorJuniorBalance = juniorToken.balanceOf(msg.sender);
        require(investorSeniorBalance > 0 || investorJuniorBalance > 0, "No tranche tokens held");

        uint256 totalInvested = totalSeniorInvested + totalJuniorInvested;
        uint256 seniorPayout = (investorSeniorBalance * totalDebt) / totalInvested;
        uint256 juniorPayout = (investorJuniorBalance * totalDebt) / totalInvested;
        uint256 totalPayout = seniorPayout + juniorPayout;
        require(totalPayout > 0, "No payout available");

        redeemed[msg.sender] = true;
        underlying.safeTransfer(msg.sender, totalPayout);

        emit Redemption(msg.sender, seniorPayout, juniorPayout);
    }
}
