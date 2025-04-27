// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PreMineRegistry
 * @notice Defines “Pre-Mine” allocation categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PreMineRegistry {
    /// @notice Types of pre-mine allocations
    enum PreMineType {
        DeveloperAllocation,   // tokens reserved for developers
        FounderAllocation,     // tokens reserved for founders
        AirdropPool,           // tokens set aside for airdrops
        TreasuryReserve,       // tokens reserved in treasury
        RewardPool             // tokens reserved for early rewards
    }

    /// @notice Attack vectors targeting pre-mine allocations
    enum AttackType {
        RugPull,               // creators remove liquidity or dump tokens
        UnauthorizedMinting,   // minting beyond the allocated amount
        GovernanceTakeover,    // hijacking governance to reallocate pre-mine
        InsiderDump,           // insiders dumping tokens immediately
        DoubleSpend            // exploiting mint logic to spend twice
    }

    /// @notice Defense mechanisms for pre-mine schemes
    enum DefenseType {
        VestingSchedule,       // time-locked vesting for allocations
        MultiSigControl,       // multi-signature requirement for transfers
        TreasuryLockup,        // smart-contract lockup of reserve funds
        IndependentAudit,      // third-party audit of mint logic
        EmissionCap            // enforce maximum total supply limit
    }

    struct Term {
        PreMineType  preMineType;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PreMineType  preMineType,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Pre-Mine term.
     * @param preMineType The pre-mine allocation category.
     * @param attack      The anticipated attack vector.
     * @param defense     The chosen defense mechanism.
     * @return id         The ID of the newly registered term.
     */
    function registerTerm(
        PreMineType  preMineType,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            preMineType: preMineType,
            attack:      attack,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit TermRegistered(id, preMineType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Pre-Mine term.
     * @param id The term ID.
     * @return preMineType The pre-mine allocation category.
     * @return attack      The attack vector.
     * @return defense     The defense mechanism.
     * @return timestamp   When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PreMineType preMineType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.preMineType, t.attack, t.defense, t.timestamp);
    }
}
