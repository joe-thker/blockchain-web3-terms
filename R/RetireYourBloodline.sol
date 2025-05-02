// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RetireBloodlineRegistry
 * @notice Defines “Retire Your Bloodline” variants along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract RetireBloodlineRegistry {
    /// @notice Types of “Retire Your Bloodline” actions
    enum RetireType {
        VoluntaryExit,      // participant opts out permanently
        ForcedExit,         // protocol enforces exit (e.g., slashing)
        LegacyTransfer,     // pass rights to a successor
        GracefulShutdown,   // phased wind-down of participation
        EmergencyEvacuation // rapid exit due to crisis
    }

    /// @notice Attack vectors targeting exits
    enum AttackType {
        PrematureExit,      // exiting before final rewards
        ExitSpamming,       // flooding exits to congest network
        FeeManipulation,    // abusing exit fee logic
        SuccessorHijack,    // malicious takeover of transferred rights
        DoSDuringExit      // denial-of-service around exit calls
    }

    /// @notice Defense mechanisms for secure exits
    enum DefenseType {
        ExitDelay,          // enforce cooldown before exit finalization
        FeeLock,            // lock a portion of fees to prevent abuse
        SignatureCheck,     // verify successor consent on transfer
        RateLimiting,       // cap number of exits per block
        CircuitBreaker      // pause new exits under attack conditions
    }

    struct Term {
        RetireType   retireType;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        RetireType    retireType,
        AttackType    attack,
        DefenseType   defense,
        uint256       timestamp
    );

    /**
     * @notice Register a new “Retire Your Bloodline” term.
     * @param retireType The exit action variant.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        RetireType   retireType,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            retireType: retireType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, retireType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return retireType The exit action variant.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            RetireType   retireType,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.retireType, t.attack, t.defense, t.timestamp);
    }
}
