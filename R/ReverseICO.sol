// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReverseICORegistry
 * @notice Defines “Reverse ICO” models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract ReverseICORegistry {
    /// @notice Types of reverse ICO structures
    enum ReverseICOType {
        TokenBurn,            // token holders burn tokens to receive new asset
        EquitySwap,           // swap existing equity tokens for new tokens
        DebtConversion,       // convert debt instruments into project tokens
        AssetBacked,          // existing asset holders receive platform tokens
        GovernanceMigration   // migrate governance token to new protocol
    }

    /// @notice Attack vectors targeting reverse ICOs
    enum AttackType {
        InsiderDump,          // insiders dump new tokens after listing
        ValuationManipulation,// misrepresenting swap rates or valuations
        FrontRunning,         // bots preempting swap transactions
        ContractBug,          // bugs in swap or burn logic
        SybilSwap             // fake identities performing repeated swaps
    }

    /// @notice Defense mechanisms for secure reverse ICOs
    enum DefenseType {
        VestingSchedules,     // lock new tokens over vesting period
        RateLimits,           // cap swaps per address/timeframe
        AuditedSwapLogic,     // third-party audit of contract code
        WhitelistKYC,         // verify participants via KYC
        MultiSigGovernance    // require multisig for critical swaps
    }

    struct Term {
        ReverseICOType model;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed     id,
        ReverseICOType      model,
        AttackType          attack,
        DefenseType         defense,
        uint256             timestamp
    );

    /**
     * @notice Register a new Reverse ICO term.
     * @param model    The reverse ICO model variant.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        ReverseICOType model,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            model:     model,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, model, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Reverse ICO term.
     * @param id The term ID.
     * @return model     The reverse ICO model variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ReverseICOType model,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.model, t.attack, t.defense, t.timestamp);
    }
}
