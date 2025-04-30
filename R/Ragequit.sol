// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RageQuitRegistry
 * @notice Defines “Rage-quit” exit modes along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract RageQuitRegistry {
    /// @notice Types of rage-quit actions
    enum QuitType {
        FullExit,         // immediately withdraw all stake/lockups
        EmergencyUnstake, // bypass cooldown to unstake instantly
        GovernanceExit,   // exit due to governance disagreement
        VaultDrain,       // withdraw from shared vault/pool
        SoftExit          // partial or gradual exit over time
    }

    /// @notice Attack vectors exploiting rage-quit
    enum AttackType {
        EarlyWithdrawal,   // withdrawing before fair distribution
        FlashLoanExit,     // use flash loans to rage-quit en masse
        VoteEscrowAbuse,   // exit to avoid negative governance votes
        RefundExploit,     // exploit refund logic on exit
        ChainSplitAttack   // rage-quit during fork to stress network
    }

    /// @notice Defense mechanisms against rage-quit exploits
    enum DefenseType {
        ExitDelay,         // enforce cooldown before exit finality
        Slashing,          // penalize early or abusive exits
        GradualUnbonding,  // staggered release of funds over time
        GovernanceLock,    // lock stake during critical votes
        ExitFees           // apply fees on emergency or early exit
    }

    struct Term {
        QuitType    quitType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        QuitType    quitType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Rage-quit term.
     * @param quitType The rage-quit action type.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        QuitType    quitType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            quitType:  quitType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, quitType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Rage-quit term.
     * @param id The term ID.
     * @return quitType  The rage-quit action type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            QuitType    quitType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.quitType, t.attack, t.defense, t.timestamp);
    }
}
