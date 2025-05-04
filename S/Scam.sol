// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScamRegistry
 * @notice Defines “Scam” schemes along with common attack vectors and defense mechanisms.
 *         Users can register and query these combinations on-chain for analysis or governance.
 */
contract ScamRegistry {
    /// @notice Categories of scams
    enum ScamType {
        PonziScheme,         // pays old investors with new investor funds
        Phishing,            // deceptive links to steal credentials
        ExitScam,            // team abandons project after raising funds
        PumpAndDump,         // inflate price then sell off holdings
        FakeICO              // fraudulent token sale with no intention to deliver
    }

    /// @notice Underlying attack vectors enabling scams
    enum AttackType {
        SocialEngineering,   // manipulation of user trust
        FakeContracts,       // deploying malicious or rug contracts
        InsiderCoordination, // team collusion to defraud investors
        DataManipulation,    // falsifying metrics or audits
        GovernanceTakeover   // seizing control via malicious votes
    }

    /// @notice Defense mechanisms to mitigate scam risks
    enum DefenseType {
        AuditedCode,         // third-party security audits
        MultiSigTreasury,    // require multiple signatures for withdrawals
        TimeLockFunds,       // time‐locked release of raised funds
        WhitelistParticipants, // KYC/whitelist contributors
        ImmutableContracts   // use non-upgradeable, immutable code
    }

    struct Term {
        ScamType    scamCategory;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ScamType     scamCategory,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Scam term.
     * @param scamCategory The scam scheme category.
     * @param attack       The enabling attack vector.
     * @param defense      The chosen defense mechanism.
     * @return id          The ID of the newly registered term.
     */
    function registerTerm(
        ScamType    scamCategory,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            scamCategory: scamCategory,
            attack:       attack,
            defense:      defense,
            timestamp:    block.timestamp
        });
        emit TermRegistered(id, scamCategory, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Scam term.
     * @param id The term ID.
     * @return scamCategory The scam scheme category.
     * @return attack       The attack vector.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ScamType    scamCategory,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.scamCategory, t.attack, t.defense, t.timestamp);
    }
}
