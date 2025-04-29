// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PyramidSchemeRegistry
 * @notice Defines “Pyramid Scheme” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PyramidSchemeRegistry {
    /// @notice Types of pyramid schemes
    enum PyramidType {
        MultiLevel,        // classic recruitment‐based pyramid
        MatrixPlan,        // fixed matrix levels with spillover
        BinaryPlan,        // two‐leg structure with fill queues
        GiftExchange,      // gift exchange or chain letter style
        Unilevel           // single level referral rewards
    }

    /// @notice Attack vectors in pyramid schemes
    enum AttackType {
        RecruitmentScam,      // false promises to recruit new members
        ExitScam,             // operators vanish with funds
        FakeAudits,           // fabricated proof of payouts
        RegulatoryEvasion,    // operating outside legal frameworks
        ChainCollapse         // promise fails when recruitment stalls
    }

    /// @notice Defense mechanisms against pyramid schemes
    enum DefenseType {
        Transparency,         // real‐time on‐chain fund flows
        IndependentAudits,    // third‐party financial reviews
        RegulatoryCompliance, // adhere to securities/anti‐fraud laws
        EscrowProtections,    // hold contributions in escrow
        WhistleblowerHotline  // enable reporting of fraud
    }

    struct Term {
        PyramidType pyramidType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PyramidType    pyramidType,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new Pyramid Scheme term.
     * @param pyramidType The category of pyramid scheme.
     * @param attack      The anticipated attack vector.
     * @param defense     The chosen defense mechanism.
     * @return id         The ID of the newly registered term.
     */
    function registerTerm(
        PyramidType pyramidType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            pyramidType: pyramidType,
            attack:      attack,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit TermRegistered(id, pyramidType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Pyramid Scheme term.
     * @param id The term ID.
     * @return pyramidType The pyramid scheme category.
     * @return attack      The attack vector.
     * @return defense     The defense mechanism.
     * @return timestamp   When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PyramidType pyramidType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.pyramidType, t.attack, t.defense, t.timestamp);
    }
}
