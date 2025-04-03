// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DustingAttackDemo
/// @notice This contract demonstrates three types of dusting attack scenarios:
/// 1. Single dusting: Sending a small ("dust") amount to a single target address.
/// 2. Multi-target dusting: Sending the same small amount to an array of target addresses.
/// 3. Repetitive dusting: Sending a small amount repeatedly to a single target address.
/// 
/// These functions are for educational purposes only. They simulate various dusting scenarios and
/// illustrate how on-chain finality and unique transfers can mitigate double-spend style issues.
contract DustingAttackDemo is Ownable, ReentrancyGuard {
    // ------------------------------------------------------------------------
    // Shared data: user deposit balances for demonstration "spends"
    // ------------------------------------------------------------------------

    /// @notice Mapping from user => Ether balance (simple deposit system).
    mapping(address => uint256) public balances;

    // ------------------------------------------------------------------------
    // (1) Race Attack demonstration
    // ------------------------------------------------------------------------
    // We prevent repeated "spend" calls by requiring a unique nonce for each spend.

    /// @notice Mapping from user => (nonce => bool) to track used nonces.
    mapping(address => mapping(uint256 => bool)) public usedNonces;

    // --- Events for demonstration ---
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RaceAttackSpend(address indexed user, uint256 amount, uint256 nonce, string description);
    event FinneyAttackDeposit(address indexed user, uint256 amount, string description);
    event Vector76AttackSimulation(address indexed user, string description);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    /// @notice Constructor sets the deployer as the owner.
    constructor() Ownable(msg.sender) {}

    // ------------------------------------------------------------------------
    // Basic deposit/withdraw logic
    // ------------------------------------------------------------------------

    /// @notice Users deposit Ether into this contract, increasing their on-chain balance.
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Must deposit > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Users withdraw their entire balance from this contract.
    function withdraw() external nonReentrant {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "No funds to withdraw");
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: bal}("");
        require(success, "Withdrawal failed");
        emit Withdrawn(msg.sender, bal);
    }

    // ------------------------------------------------------------------------
    // (1) Race Attack demonstration & prevention
    // ------------------------------------------------------------------------

    /// @notice Simulates a race attack spend by requiring a unique nonce.
    /// @param amount The amount to spend.
    /// @param nonce A user-chosen unique nonce for this spend.
    function raceAttackSpend(uint256 amount, uint256 nonce) external nonReentrant {
        require(amount > 0, "Spend amount must be > 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(!usedNonces[msg.sender][nonce], "Nonce already used (double-spend attempt?)");
        
        // Mark the nonce as used.
        usedNonces[msg.sender][nonce] = true;
        // Deduct the amount from the user's balance.
        balances[msg.sender] -= amount;
        emit RaceAttackSpend(msg.sender, amount, nonce, "Race Attack spend with nonce-based prevention");
    }

    // ------------------------------------------------------------------------
    // (2) Finney Attack demonstration
    // ------------------------------------------------------------------------
    /// @notice Simulates a Finney Attack deposit scenario.
    /// When a transaction is mined, its state is final, mitigating replays.
    function finneyAttackDeposit() external payable nonReentrant {
        require(msg.value > 0, "No Ether sent");
        balances[msg.sender] += msg.value;
        emit FinneyAttackDeposit(msg.sender, msg.value, "On-chain finality mitigates Finney Attack replays");
    }

    // ------------------------------------------------------------------------
    // (3) Vector76 Attack demonstration
    // ------------------------------------------------------------------------
    /// @notice Demonstrates a Vector76 Attack scenario by showing that on-chain state is final once mined.
    function vector76AttackDemo() external nonReentrant {
        emit Vector76AttackSimulation(msg.sender, "Local on-chain state final from contract's perspective");
    }
}
