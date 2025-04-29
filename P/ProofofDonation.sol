// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ProofOfDonationRegistry
 * @notice Defines “Proof-of-Donation” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract ProofOfDonationRegistry {
    /// @notice Variants of proof-of-donation schemes
    enum DonationProofType {
        OnChainReceipt,       // direct on-chain donation record
        NFTBadge,             // badge/NFT minted as proof
        OffChainReference,    // off-chain receipt URI stored on-chain
        MatchedDonation,      // proof that donation was matched by sponsor
        MilestoneBadge        // badge earned upon cumulative donations
    }

    /// @notice Attack vectors targeting proof-of-donation
    enum AttackType {
        FalseClaim,           // claiming a donation that wasn’t made
        ReplayAttack,         // replaying an old donation transaction
        AddressTampering,     // altering recipient address in proof
        SignatureForgery,     // forging donation signatures
        RefundExploit         // exploiting refund logic to fake donation
    }

    /// @notice Defense mechanisms for proof-of-donation
    enum DefenseType {
        SignatureVerification, // verify donor’s signed confirmation
        NonceTracking,         // prevent replay with unique nonces
        Whitelist,             // restrict to approved donors or campaigns
        MultiSigConfirmation,  // require multi-sig for high-value proofs
        OnChainAuditTrail      // immutable event log of all proofs
    }

    struct Term {
        DonationProofType proofType;
        AttackType        attack;
        DefenseType       defense;
        uint256           timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed        id,
        DonationProofType      proofType,
        AttackType             attack,
        DefenseType            defense,
        uint256                timestamp
    );

    /**
     * @notice Register a new Proof-of-Donation term.
     * @param proofType The proof-of-donation variant.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        DonationProofType proofType,
        AttackType        attack,
        DefenseType       defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            proofType: proofType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, proofType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Proof-of-Donation term.
     * @param id The term ID.
     * @return proofType The proof-of-donation variant.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            DonationProofType proofType,
            AttackType        attack,
            DefenseType       defense,
            uint256           timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.proofType, t.attack, t.defense, t.timestamp);
    }
}
