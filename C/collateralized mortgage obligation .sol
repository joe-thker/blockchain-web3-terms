// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice ERC20 token representing senior tranche investments.
contract SeniorTrancheToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {}

    /// @notice Mint tokens; callable only by the owner (the CMO contract).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

/// @notice ERC20 token representing junior tranche investments.
contract JuniorTrancheToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {}

    /// @notice Mint tokens; callable only by the owner (the CMO contract).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

/// @notice Collateralized Mortgage Obligation (CMO) contract.
/// Investors deposit funds during an investment phase to receive tranche tokens.
/// After activation, the owner records mortgage payments, and when the CMO matures,
/// investors redeem their tranche tokens for a share of the mortgage payments.
contract CollateralizedMortgageObligation is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Underlying ERC20 token (e.g., a stablecoin used for mortgage payments).
    IERC20 public immutable underlying;

    // Tranche tokens.
    SeniorTrancheToken public seniorToken;
    JuniorTrancheToken public juniorToken;

    // Investment caps.
    uint256 public seniorCap;
    uint256 public juniorCap;

    // Total funds invested per tranche.
    uint256 public totalSeniorInvested;
    uint256 public totalJuniorInvested;

    // Senior tranche target payout (e.g., principal plus a promised return).
    uint256 public seniorTarget;

    // Accumulated mortgage payments.
    uint256 public totalMortgagePayments;

    // Lifecycle states.
    enum State { Investment, Active, Matured }
    State public state;

    // Track whether an investor has redeemed.
    mapping(address => bool) public redeemed;

    // --- Events ---
    event InvestedSenior(address indexed investor, uint256 amount);
    event InvestedJunior(address indexed investor, uint256 amount);
    event CMOActivated();
    event MortgagePaymentRecorded(uint256 amount);
    event CMOMatured();
    event Redemption(address indexed investor, uint256 seniorPayout, uint256 juniorPayout);

    /// @notice Initializes the CMO.
    /// @param _underlying Address of the underlying ERC20 token.
    /// @param _seniorCap Maximum investment for the senior tranche.
    /// @param _juniorCap Maximum investment for the junior tranche.
    /// @param _seniorTarget Total amount senior tranche investors are promised.
    /// @param seniorName Name for the senior tranche token.
    /// @param seniorSymbol Symbol for the senior tranche token.
    /// @param juniorName Name for the junior tranche token.
    /// @param juniorSymbol Symbol for the junior tranche token.
    constructor(
        address _underlying,
        uint256 _seniorCap,
        uint256 _juniorCap,
        uint256 _seniorTarget,
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
        seniorTarget = _seniorTarget;
        state = State.Investment;

        seniorToken = new SeniorTrancheToken(seniorName, seniorSymbol);
        seniorToken.transferOwnership(address(this));

        juniorToken = new JuniorTrancheToken(juniorName, juniorSymbol);
        juniorToken.transferOwnership(address(this));
    }

    /// @notice Investors deposit funds to invest in the senior tranche.
    function investSenior(uint256 amount) external nonReentrant {
        require(state == State.Investment, "Not in investment phase");
        require(amount > 0, "Amount must be > 0");
        require(totalSeniorInvested + amount <= seniorCap, "Senior tranche cap exceeded");

        underlying.safeTransferFrom(msg.sender, address(this), amount);
        totalSeniorInvested += amount;
        seniorToken.mint(msg.sender, amount);

        emit InvestedSenior(msg.sender, amount);
    }

    /// @notice Investors deposit funds to invest in the junior tranche.
    function investJunior(uint256 amount) external nonReentrant {
        require(state == State.Investment, "Not in investment phase");
        require(amount > 0, "Amount must be > 0");
        require(totalJuniorInvested + amount <= juniorCap, "Junior tranche cap exceeded");

        underlying.safeTransferFrom(msg.sender, address(this), amount);
        totalJuniorInvested += amount;
        juniorToken.mint(msg.sender, amount);

        emit InvestedJunior(msg.sender, amount);
    }

    /// @notice Owner activates the CMO, moving from Investment to Active phase.
    function activateCMO() external onlyOwner nonReentrant {
        require(state == State.Investment, "CMO not in investment phase");
        state = State.Active;
        emit CMOActivated();
    }

    /// @notice Owner records a mortgage payment. Payments are accumulated.
    /// @param amount Amount of the mortgage payment.
    function recordMortgagePayment(uint256 amount) external onlyOwner nonReentrant {
        require(state == State.Active, "CMO not active");
        require(amount > 0, "Amount must be > 0");
        underlying.safeTransferFrom(msg.sender, address(this), amount);
        totalMortgagePayments += amount;
        emit MortgagePaymentRecorded(amount);
    }

    /// @notice Owner marks the CMO as matured, ending the payment collection.
    function matureCMO() external onlyOwner nonReentrant {
        require(state == State.Active, "CMO not active");
        state = State.Matured;
        emit CMOMatured();
    }

    /// @notice Investors redeem their tranche tokens for a share of the mortgage payments.
    /// Senior tranche investors have priority.
    function redeem() external nonReentrant {
        require(state == State.Matured, "CMO not matured");
        require(!redeemed[msg.sender], "Already redeemed");

        uint256 investorSeniorBalance = seniorToken.balanceOf(msg.sender);
        uint256 investorJuniorBalance = juniorToken.balanceOf(msg.sender);
        require(investorSeniorBalance > 0 || investorJuniorBalance > 0, "No tranche tokens held");

        uint256 seniorPayout;
        uint256 juniorPayout;

        if (totalMortgagePayments <= seniorTarget) {
            // Only senior tranche receives a proportional share if payments fall short.
            if (totalSeniorInvested > 0) {
                seniorPayout = (investorSeniorBalance * totalMortgagePayments) / totalSeniorInvested;
            }
            juniorPayout = 0;
        } else {
            // Senior tranche receives full seniorTarget; junior tranche gets the remainder.
            seniorPayout = (investorSeniorBalance * seniorTarget) / totalSeniorInvested;
            uint256 remainingPayments = totalMortgagePayments - seniorTarget;
            if (totalJuniorInvested > 0) {
                juniorPayout = (investorJuniorBalance * remainingPayments) / totalJuniorInvested;
            }
        }

        redeemed[msg.sender] = true;
        uint256 totalPayout = seniorPayout + juniorPayout;
        require(totalPayout > 0, "No payout available");
        underlying.safeTransfer(msg.sender, totalPayout);

        emit Redemption(msg.sender, seniorPayout, juniorPayout);
    }
}
