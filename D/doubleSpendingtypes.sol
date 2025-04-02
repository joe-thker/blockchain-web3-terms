// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DoubleSpendingTypesDemo
/// @notice Demonstrates three types of double-spend attacks (Race Attack, Finney Attack, Vector76 Attack),
/// along with on-chain mitigations. This contract is for educational demonstration only.
contract DoubleSpendingTypesDemo is ReentrancyGuard {
    // ------------------------------------------------------------------------
    // Shared data: user deposit balances for demonstration "spends."
    // ------------------------------------------------------------------------

    /// @notice Mapping from user => Ether balance (simple deposit system).
    mapping(address => uint256) public balances;

    // ------------------------------------------------------------------------
    // (1) Race Attack demonstration
    // ------------------------------------------------------------------------
    // We prevent repeated "spend" calls by requiring a unique nonce.

    /// @notice Mapping from user => (nonce => bool) to mark used nonces for each spend operation.
    mapping(address => mapping(uint256 => bool)) public usedNonces;

    // --- Events for demonstration ---
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    event RaceAttackSpend(address indexed user, uint256 amount, uint256 nonce, string description);
    event FinneyAttackDeposit(address indexed user, uint256 amount, string description);
    event Vector76AttackSimulation(address indexed user, string description);

    // ------------------------------------------------------------------------
    // Basic deposit/withdraw logic
    // ------------------------------------------------------------------------

    /// @notice Users deposit Ether, credited to their on-chain balance.
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Must deposit > 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Users withdraw their entire balance (a simple pull pattern).
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

    /// @notice "Spend" scenario requiring a unique nonce to mitigate race/replay attacks.
    /// @param amount The portion of the user's on-chain balance they want to spend.
    /// @param nonce A unique user-chosen identifier to ensure no double usage.
    function raceAttackSpend(uint256 amount, uint256 nonce) external nonReentrant {
        require(amount > 0, "Spend amount must be > 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(!usedNonces[msg.sender][nonce], "Nonce already used (race attack attempt?)");

        // Mark nonce as used
        usedNonces[msg.sender][nonce] = true;

        // Deduct from user’s on-chain balance
        balances[msg.sender] -= amount;

        // In a real scenario, you'd forward or burn these funds. For demonstration, they're removed from user balance.

        emit RaceAttackSpend(msg.sender, amount, nonce, "Race Attack spend with nonce-based replay prevention");
    }

    // ------------------------------------------------------------------------
    // (2) Finney Attack demonstration
    // ------------------------------------------------------------------------
    // Usually an off-chain ephemeral transaction trick. On-chain finality ensures 
    // once included in a block, it's recognized by this contract as final.

    /// @notice Simulates a Finney Attack deposit. If re-broadcast, only the mined transaction is final on-chain.
    function finneyAttackDeposit() external payable nonReentrant {
        require(msg.value > 0, "No Ether sent");
        balances[msg.sender] += msg.value;

        emit FinneyAttackDeposit(msg.sender, msg.value, "On-chain finality mitigates typical Finney Attack replays");
    }

    // ------------------------------------------------------------------------
    // (3) Vector76 Attack demonstration
    // ------------------------------------------------------------------------
    // Involves chain reorganizations or acceptance differences. Once a transaction is mined, the local 
    // contract state sees it as final. Real usage might wait multiple confirmations off-chain.

    /// @notice Demonstrates local on-chain finality for a transaction once it's in a mined block.
    function vector76AttackDemo() external nonReentrant {
        // We do nothing but emit an event showing the transaction was recognized on this chain fork.
        emit Vector76AttackSimulation(msg.sender, "Local on-chain state final from contract's perspective");
    }
}
