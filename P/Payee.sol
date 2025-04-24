// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PayeeRegistry
 * @notice Defines “Payee” categories along with common attack vectors
 *         and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract PayeeRegistry {
    /// @notice Types of payees in a payment system
    enum PayeeType {
        Individual,        // a single person
        Merchant,          // a business or vendor
        ServiceProvider,   // e.g., utility or subscription service
        SmartContract,     // on-chain contract receiving funds
        EscrowAccount      // held by a third-party until release
    }

    /// @notice Attack vectors targeting payees or payments
    enum AttackType {
        Phishing,          // tricking user to send funds to wrong payee
        AddressTampering,  // modifying payee address in transit
        DoubleSpend,       // attempting to spend same funds twice
        Censorship,        // blocking payee from receiving funds
        ManInTheMiddle     // intercepting and altering payment data
    }

    /// @notice Defense mechanisms to protect payments to payees
    enum DefenseType {
        AddressVerification, // checksum or on-chain ENS lookup
        MultiSig,            // require multiple approvals for large payouts
        Whitelist,           // only approved payee addresses allowed
        TransactionReplayProtection, // nonce or timestamp checks
        Encryption           // encrypt payment instructions off-chain
    }

    struct Term {
        PayeeType   payeeType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PayeeType   payeeType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new Payee term.
     * @param payeeType The category of the payee.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        PayeeType   payeeType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            payeeType:   payeeType,
            attack:      attack,
            defense:     defense,
            timestamp:   block.timestamp
        });
        emit TermRegistered(id, payeeType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Payee term.
     * @param id The term ID.
     * @return payeeType The payee category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PayeeType   payeeType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.payeeType, t.attack, t.defense, t.timestamp);
    }
}
