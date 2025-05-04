// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SatoshiRegistry
 * @notice Defines “Satoshi (SATS)” roles/contexts along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract SatoshiRegistry {
    /// @notice Contexts or roles for “Satoshi”
    enum SatoshiType {
        SmallestUnit,        // the indivisible 0.00000001 BTC unit
        BlockReward,         // reward given to miner per block
        EarlyInvestor,       // first adopters/miners of Bitcoin
        HumbleHodler,        // long-term holder mentality
        NetworkFounder       // the pseudonymous Bitcoin creator
    }

    /// @notice Attack vectors targeting satoshi contexts
    enum AttackType {
        DustSpam,            // sending tiny outputs to bloat UTXO set
        RewardHalving,       // protocol-driven reduction of block reward
        ReplayOnFork,        // replaying transactions to steal sats
        KeyExposure,         // loss or theft of private keys holding sats
        IdentityReveal       // de-anonymizing the real Satoshi
    }

    /// @notice Defense mechanisms for securing satoshi contexts
    enum DefenseType {
        UTXOCleanup,         // consolidation to remove dust outputs
        FeeAdjustment,       // dynamic fees post-halving to sustain security
        ReplayProtection,    // use chain ID or nonces to prevent replay
        ColdStorage,         // offline key storage for private keys
        PrivacyProtocols     // use mixers or CoinJoins for identity protection
    }

    struct Term {
        SatoshiType  context;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        SatoshiType    context,
        AttackType     attack,
        DefenseType    defense,
        uint256        timestamp
    );

    /**
     * @notice Register a new Satoshi term.
     * @param context  The Satoshi context or role.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        SatoshiType context,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            context:   context,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, context, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Satoshi term.
     * @param id  The term ID.
     * @return context   The Satoshi context or role.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            SatoshiType context,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.context, t.attack, t.defense, t.timestamp);
    }
}
