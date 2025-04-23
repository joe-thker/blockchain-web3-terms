// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OTCTradingRegistry
 * @notice Defines “Over-the-Counter (OTC) Trading” models along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain for analysis or governance.
 */
contract OTCTradingRegistry {
    /// @notice Types of OTC trading
    enum TradingType {
        Spot,                // immediate delivery trades
        Derivatives,         // forwards, swaps, options
        PeerToPeer,          // direct P2P matched trades
        BrokerFacilitated,   // via an OTC broker
        DarkPool,            // large block trades anonymously
        Synthetic            // tokenized OTC positions
    }

    /// @notice Attack vectors targeting OTC trading
    enum AttackType {
        CounterpartyDefault, // failure to settle by counterparty
        PriceManipulation,   // false pricing to mislead party
        SettlementDelay,     // intentional slowdown of settlement
        InformationLeakage,  // leaking trade plans to third parties
        RegulatoryEvasion    // bypassing KYC/AML or other rules
    }

    /// @notice Defense mechanisms for OTC trading
    enum DefenseType {
        Escrow,              // funds held in escrow contract
        Netting,             // bilateral or multilateral netting
        Collateralization,   // requiring upfront collateral
        OnchainSettlement,   // settlement via blockchain finality
        Insurance            // third-party insurance or guarantees
    }

    struct Term {
        TradingType trading;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        TradingType trading,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new OTC Trading term.
     * @param trading The OTC trading model.
     * @param attack  The anticipated attack vector.
     * @param defense The chosen defense mechanism.
     * @return id      The ID of the registered term.
     */
    function registerTerm(
        TradingType trading,
        AttackType  attack,
        DefenseType defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            trading:   trading,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, trading, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return trading   The OTC trading model.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            TradingType trading,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.trading, t.attack, t.defense, t.timestamp);
    }
}
