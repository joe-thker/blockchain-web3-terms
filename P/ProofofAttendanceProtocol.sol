// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PoAPRegistry
 * @notice Defines “Proof of Attendance Protocol (PoAP)” event categories along with
 *         common attack vectors and defense mechanisms. Users can register and query
 *         these combinations on-chain for analysis or governance.
 */
contract PoAPRegistry {
    /// @notice Types of PoAP events
    enum PoAPType {
        PhysicalEvent,     // in-person event badge
        VirtualEvent,      // online/streamed event badge
        HybridEvent,       // mix of on-chain and off-chain attendance
        MilestoneBadge,    // specific achievement or milestone
        SeasonalBadge      // recurring or seasonal event badge
    }

    /// @notice Attack vectors targeting PoAP issuance
    enum AttackType {
        SpamClaim,         // automated or repeated badge claims
        SybilClaim,        // creating fake identities to claim multiple badges
        KeyCompromise,     // stealing issuer’s signing key
        ReplayAttack,      // reusing proof data to mint multiple badges
        Phishing           // tricking users into revealing claim tokens
    }

    /// @notice Defense mechanisms for PoAP systems
    enum DefenseType {
        SignatureVerification, // validate signed attendance proofs
        NonceManagement,       // one-time nonces to prevent replays
        Whitelist,             // pre-approved attendee list
        RateLimiting,          // throttle claim frequency per address
        MultiSigMint           // require multiple issuers to mint badge
    }

    struct Term {
        PoAPType    poapType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PoAPType    poapType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new PoAP term.
     * @param poapType The PoAP event category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PoAPType    poapType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            poapType:    poapType,
            attack:      attack,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit TermRegistered(id, poapType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered PoAP term.
     * @param id The term ID.
     * @return poapType  The PoAP event category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PoAPType    poapType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.poapType, t.attack, t.defense, t.timestamp);
    }
}
