// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfBurnRegistry
 * @notice Defines “Proof-of-Burn” variants along with common attack vectors
 *         and defense mechanisms. Users can register and query these combinations
 *         on-chain for analysis or governance.
 */
contract ProofOfBurnRegistry {
    /// @notice Variants of Proof-of-Burn mechanisms
    enum BurnType {
        ConsensusBurn,      // burn to participate in consensus (PoB chain)
        FeeBurn,            // burn protocol fees (e.g. EIP-1559)
        RedemptionBurn,     // burn tokens to redeem real-world value
        NFTBurnForMint,     // burn NFT to mint another
        TokenSwapBurn       // burn one token as part of swap mechanism
    }

    /// @notice Attack vectors targeting Proof-of-Burn systems
    enum AttackType {
        ForgedBurnProof,    // submitting fabricated burn events
        ReplayAttack,       // replaying old burn transactions
        UnauthorizedBurn,   // front-running or spurious burns
        DustSpam,           // flooding with tiny burns to manipulate stats
        OracleManipulation  // feeding wrong burn data to oracles
    }

    /// @notice Defense mechanisms for securing Proof-of-Burn
    enum DefenseType {
        OnChainVerification, // verify burn events via on-chain logs
        NonceTracking,       // prevent replay with unique nonces
        MultiSigApproval,    // require multisig for large burns
        RateLimiting,        // throttle burn frequency/amount
        BurnReceipts         // emit detailed burn receipt events
    }

    struct Term {
        BurnType    burnType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        BurnType    burnType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Proof-of-Burn term.
     * @param burnType  The burn mechanism variant.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        BurnType    burnType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            burnType:   burnType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, burnType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Proof-of-Burn term.
     * @param id The term ID.
     * @return burnType  The burn mechanism variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            BurnType    burnType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.burnType, t.attack, t.defense, t.timestamp);
    }
}
