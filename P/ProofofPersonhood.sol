// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfPersonhoodRegistry
 * @notice Defines “Proof of Personhood” schemes along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ProofOfPersonhoodRegistry {
    /// @notice Types of proof-of-personhood mechanisms
    enum PoPType {
        SocialGraph,            // attestation via trusted social connections
        SMSVerification,        // one-time SMS code to a unique phone
        ProofOfHumanity,        // on-chain identity registry (e.g., ERC-721)
        BiometricScan,          // biometric hash comparison
        ZKAnonymousCredential   // zero-knowledge anonymous credential
    }

    /// @notice Attack vectors targeting personhood proofs
    enum AttackType {
        SybilAttack,            // creating many fake identities
        BotAutomation,          // using bots to pass checks en masse
        Collusion,              // group of attackers vouching for each other
        IdentityTheft,          // stealing someone’s on-chain proof
        DeepFake                // faking biometrics with AI
    }

    /// @notice Defense mechanisms for personhood schemes
    enum DefenseType {
        CAPTCHA,                // human challenge-response test
        BiometricVerification,  // liveness checks and multi-factor biometrics
        SocialRecovery,         // recovery via social network attestations
        HardwareToken,          // hardware wallet or secure enclave check
        ReputationSystem        // track reputation and flag anomalies
    }

    struct Term {
        PoPType     popType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PoPType     popType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Proof of Personhood term.
     * @param popType   The personhood mechanism type.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        PoPType     popType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            popType:    popType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, popType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Proof of Personhood term.
     * @param id   The term ID.
     * @return popType   The personhood mechanism type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PoPType     popType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.popType, t.attack, t.defense, t.timestamp);
    }
}
