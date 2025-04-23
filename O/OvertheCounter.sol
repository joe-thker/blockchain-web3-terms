// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OTCRegistry
 * @notice Defines “Over-The-Counter (OTC)” market types along with common
 *         attack vectors and defense mechanisms. Users can register and
 *         query these combinations on-chain.
 */
contract OTCRegistry {
    /// @notice Types of OTC transaction models
    enum OTCType {
        Direct,           // direct peer-to-peer trades
        BrokerFacilitated,// trades via a broker
        DarkPool,         // anonymous block trades
        PeerToPeer,       // P2P with matching platform
        Institutional     // large institutional desks
    }

    /// @notice Attack vectors targeting OTC markets
    enum AttackType {
        CounterpartyDefault, // party fails to deliver
        PriceManipulation,   // false pricing to mislead counterparty
        SettlementDelay,     // intentionally slow settlement
        InformationLeakage,  // leaking trade intentions
        ComplianceEvasion    // bypassing KYC/AML controls
    }

    /// @notice Defense mechanisms for OTC markets
    enum DefenseType {
        CollateralSegregation, // segregated collateral accounts
        ThirdPartyCustody,     // neutral custodian holds assets
        SmartContractEscrow,   // on-chain escrow contract
        LegalAgreements,       // enforceable legal contracts
        ReputationSystem       // reputation-based trust scoring
    }

    struct OTCTerm {
        OTCType      otcType;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => OTCTerm) public terms;

    event OTCTermRegistered(
        uint256 indexed id,
        OTCType      otcType,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new OTC term.
     * @param otcType  The OTC model type.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the registered term.
     */
    function registerTerm(
        OTCType      otcType,
        AttackType   attack,
        DefenseType  defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = OTCTerm({
            otcType:   otcType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit OTCTermRegistered(id, otcType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered OTC term.
     * @param id The term ID.
     * @return otcType   The OTC model type.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            OTCType      otcType,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        OTCTerm storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.otcType, t.attack, t.defense, t.timestamp);
    }
}
