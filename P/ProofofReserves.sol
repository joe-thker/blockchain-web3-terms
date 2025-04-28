// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfReservesRegistry
 * @notice Defines “Proof of Reserves” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ProofOfReservesRegistry {
    /// @notice Types of proof-of-reserves approaches
    enum ReservesType {
        OnChainMerkle,        // Merkle‐tree proof of balances on‐chain
        AuditorReport,        // periodic third‐party audit reports
        SmartContractLockup,  // reserves locked in a contract
        ZKProof,              // zero-knowledge proof of reserves
        SignedBalanceSheet    // signed off‐chain balance sheet attestations
    }

    /// @notice Attack vectors targeting proof-of-reserves systems
    enum AttackType {
        FalseAttestation,     // submitting fake proofs or signatures
        OracleManipulation,   // feeding incorrect price/oracle data
        ReserveMisreporting,  // omitting liabilities or overvaluing assets
        CollateralSweep,      // draining reserves after proof published
        GovernanceTakeover    // hijacking system to alter proofs
    }

    /// @notice Defense mechanisms to secure proof-of-reserves
    enum DefenseType {
        CryptographicVerification, // verify Merkle proofs on‐chain
        MultiAuditor,              // require multiple independent audits
        TimeLock,                  // delay withdrawals after proof
        zkIntegrity,               // enforce zk‐SNARK proof checks
        MultiSigControl            // multisig for reserve movements
    }

    struct Term {
        ReservesType reservesType;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        ReservesType reservesType,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Proof of Reserves term.
     * @param reservesType The proof-of-reserves approach.
     * @param attack       The anticipated attack vector.
     * @param defense      The chosen defense mechanism.
     * @return id          The ID of the newly registered term.
     */
    function registerTerm(
        ReservesType reservesType,
        AttackType   attack,
        DefenseType  defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            reservesType: reservesType,
            attack:       attack,
            defense:      defense,
            timestamp:    block.timestamp
        });
        emit TermRegistered(id, reservesType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Proof of Reserves term.
     * @param id The term ID.
     * @return reservesType The proof-of-reserves approach.
     * @return attack       The attack vector.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            ReservesType reservesType,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.reservesType, t.attack, t.defense, t.timestamp);
    }
}
