// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DoubleSpendAttackExamples
/// @notice Demonstrates conceptual scenarios for various double-spend attack types (Race Attack, Finney Attack, Vector76 Attack),
/// plus how on-chain logic might mitigate them. This is for educational, demonstration-only use.
contract DoubleSpendAttackExamples is ReentrancyGuard, Ownable {
    /// @notice Mapping from user => Ether balance deposited, as a demonstration of a shared resource.
    mapping(address => uint256) public balances;

    /// @notice Mapping from user => (nonce => bool) for replay prevention in "Race Attack" style scenarios.
    mapping(address => mapping(uint256 => bool)) public usedNonces;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    event RaceAttackSimulated(address indexed attacker, uint256 indexed nonce, bool success, string description);
    event FinneyAttackSimulated(address indexed attacker, bool success, string description);
    event Vector76AttackSimulated(address indexed attacker, bool success, string description);

    /// @notice Constructor sets deployer as the owner for potential admin logic.
    constructor() Ownable(msg.sender) {}

    // ------------------------------------------------------------------------
    // Basic deposit/withdraw logic to have a “shared resource” that can be “spent.”
    // ------------------------------------------------------------------------

    /// @notice Users deposit Ether into this contract, increments their on-chain balance.
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Must deposit > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Users withdraw their entire balance (a simple pull pattern).
    function withdraw() external nonReentrant {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "No funds to withdraw");

        // Clear user’s balance before sending Ether
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: bal}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, bal);
    }

    // ------------------------------------------------------------------------
    // Race Attack Demonstration
    // ------------------------------------------------------------------------
    // A Race Attack (a typical double-spend scenario in off-chain or PoW contexts) can sometimes be mitigated
    // by on-chain unique nonces or replay-protected calls.

    /// @notice Demonstrates a “spend” with a required nonce to mitigate replays or race conditions.
    /// If the nonce was already used by the user, revert.
    /// @param nonce A unique nonce to ensure no replay of the same “spend” call.
    /// @param spendAmount The amount of the user’s balance they want to spend.
    function simulateRaceAttack(uint256 nonce, uint256 spendAmount) external nonReentrant {
        require(spendAmount > 0, "Spend amount must be > 0");
        require(balances[msg.sender] >= spendAmount, "Insufficient balance");
        require(!usedNonces[msg.sender][nonce], "Nonce already used: potential replay/race attack prevented");

        // Mark the nonce as used
        usedNonces[msg.sender][nonce] = true;

        // Deduct from user’s on-chain balance (this is the “spend”)
        balances[msg.sender] -= spendAmount;

        // This demonstration does not actually transfer the funds anywhere else 
        // (like sending to a merchant). It's just to show the logic.

        emit RaceAttackSimulated(msg.sender, nonce, true, "Race Attack mitigation with nonce usage");
    }

    // ------------------------------------------------------------------------
    // Finney Attack Demonstration
    // ------------------------------------------------------------------------
    // A Finney Attack is where a user sends a transaction with a certain value, 
    // but then quickly re-broadcasts a new transaction at a different gas price, 
    // attempting to cause confusion or double-spend if a merchant expects the payment 
    // in an ephemeral transaction pool scenario. On-chain, we can't easily fix it, 
    // but we can demonstrate a check if the deposit was actually mined.

    /// @notice Demonstrates a Finney Attack scenario by verifying the msg.value is nonzero, 
    /// and once deposited, it’s recognized. If the attacker tries a second transaction 
    /// with the same ephemeral states, it won't repeat on chain.
    function simulateFinneyAttack() external payable nonReentrant {
        // If user tries to do tricky ephemeral replays, 
        // once we have the state minted in a block, it's final on chain.
        // This is conceptual only.
        require(msg.value > 0, "Must send Ether to simulate Finney Attack deposit");
        balances[msg.sender] += msg.value;

        emit FinneyAttackSimulated(msg.sender, true, "On-chain finality prevents typical Finney double-spend");
    }

    // ------------------------------------------------------------------------
    // Vector76 Attack Demonstration
    // ------------------------------------------------------------------------
    // Vector76 is a more advanced double-spend scenario combining subtle chain reorg or block acceptance 
    // at different nodes. On-chain finality once again is the mitigation if you wait enough confirmations.

    /// @notice Demonstrates a “Vector76 Attack” scenario by stating that waiting for multiple confirmations 
    /// is recommended. On chain, once a transaction is included, it’s recognized in this contract’s state, 
    /// so a chain reorg or subtle acceptance issue is out of scope for this local contract state.
    function simulateVector76Attack() external nonReentrant {
        // There's no direct code to mitigate, 
        // but we can illustrate that once we do the on-chain state update, 
        // the local ledger is final from the contract’s perspective.
        // For demonstration, we do nothing but emit an event.
        emit Vector76AttackSimulated(msg.sender, true, "Local on-chain finality mitigating Vector76 scenario");
    }

    // ------------------------------------------------------------------------
    // Additional demonstration or expansion can be done. This code is purely conceptual.
    // ------------------------------------------------------------------------

    /// @notice In real usage, you might handle more advanced deposit/spend logic or cross-contract calls.
    /// On-chain finality and unique nonces are typical code-level mitigations for replays / double spends 
    /// at the contract layer.
}
