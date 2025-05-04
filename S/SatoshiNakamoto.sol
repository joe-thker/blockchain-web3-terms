// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SatoshiNakamotoRegistry
 * @notice Defines “Satoshi Nakamoto” personas/roles along with common
 *         attack vectors (risks) and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract SatoshiNakamotoRegistry {
    /// @notice Known personas or roles of Satoshi Nakamoto
    enum PersonaType {
        WhitepaperAuthor,    // wrote the Bitcoin whitepaper
        ReferenceClientDev,  // initial Bitcoin client development
        EarlyMiner,          // mined the first Bitcoin blocks
        NetworkArchitect,    // designed protocol rules and incentives
        PseudonymousLegend   // maintained anonymity and mystery
    }

    /// @notice Attack vectors targeting the Satoshi persona
    enum AttackType {
        IdentityDeanonymize, // attempts to reveal real identity
        ReputationSmear,     // false claims damaging legacy
        DocumentForgery,     // fake messages or patches in Satoshi's name
        SocialEngineering,   // tricking community via fake Satoshi channels
        LegalCompulsion      // court orders to force identity disclosure
    }

    /// @notice Defense mechanisms preserving the Satoshi persona
    enum DefenseType {
        CryptographicProof,  // signed messages proving authenticity
        CommunityVetting,    // peer review of claimed Satoshi communications
        ImmutableArchives,   // preserve original writings on-chain
        MultiSigProofs,      // use multiple keys to validate messages
        AnonymityTools       // use mixers and privacy tech to hide identity
    }

    struct Term {
        PersonaType persona;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PersonaType  persona,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Satoshi Nakamoto term.
     * @param persona  The Satoshi Nakamoto persona/role.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PersonaType persona,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            persona:   persona,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, persona, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return persona   The Satoshi Nakamoto persona/role.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PersonaType persona,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.persona, t.attack, t.defense, t.timestamp);
    }
}
