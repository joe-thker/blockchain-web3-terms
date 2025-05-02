// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReplayAttackRegistry
 * @notice Defines “Replay Attack” variants along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ReplayAttackRegistry {
    /// @notice Variants of replay attacks
    enum ReplayAttackType {
        SameChain,         // replaying a transaction on the same chain
        CrossChain,        // replaying on a fork or parallel chain
        ContractReplay,    // replaying calls to the same contract
        SignatureReuse,    // reusing a valid signature for multiple txs
        TimestampReplay    // replaying delayed transactions
    }

    /// @notice Attack vectors in replay attacks
    enum AttackType {
        TxHashResubmission,  // resubmitting a previously seen tx hash
        SignedMessageReplay, // replaying an off-chain signed message on-chain
        ForkExploitation,    // exploiting chain forks to reuse txs
        NonceManipulation,   // resetting or bypassing nonce checks
        CrossChainBridge     // reusing messages across bridge endpoints
    }

    /// @notice Defense mechanisms against replay attacks
    enum DefenseType {
        NonceTracking,       // strict per-account nonces
        EIP155ChainId,       // include chain ID in signed payloads
        ReplayGuards,        // contract-level replay guard mappings
        TimestampValidation, // reject stale timestamps
        DomainSeparation     // separate domain params in signatures
    }

    struct Term {
        ReplayAttackType attackVariant;
        AttackType       attack;
        DefenseType      defense;
        uint256          timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed    id,
        ReplayAttackType   attackVariant,
        AttackType         attack,
        DefenseType        defense,
        uint256            timestamp
    );

    /**
     * @notice Register a new Replay Attack term.
     * @param attackVariant The replay attack variant.
     * @param attack        The anticipated attack vector.
     * @param defense       The chosen defense mechanism.
     * @return id           The ID of the newly registered term.
     */
    function registerTerm(
        ReplayAttackType attackVariant,
        AttackType       attack,
        DefenseType      defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            attackVariant: attackVariant,
            attack:        attack,
            defense:       defense,
            timestamp:     block.timestamp
        });
        emit TermRegistered(id, attackVariant, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Replay Attack term.
     * @param id The term ID.
     * @return attackVariant The replay attack variant.
     * @return attack        The attack vector.
     * @return defense       The defense mechanism.
     * @return timestamp     When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ReplayAttackType attackVariant,
            AttackType       attack,
            DefenseType      defense,
            uint256          timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.attackVariant, t.attack, t.defense, t.timestamp);
    }
}
