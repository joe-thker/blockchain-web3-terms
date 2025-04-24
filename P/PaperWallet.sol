// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PaperWalletRegistry
 * @notice Defines “Paper Wallet” types along with common attack vectors
 *         and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract PaperWalletRegistry {
    /// @notice Types of paper wallets
    enum PaperWalletType {
        Printable,         // simple printed key/QR code
        BIP38Encrypted,    // encrypted with BIP-38 passphrase
        BrainWallet,       // passphrase memorization
        MetalPlate,        // key engraved on metal for durability
        OfflineGenerated   // generated offline and printed
    }

    /// @notice Attack vectors targeting paper wallets
    enum AttackType {
        PhysicalTheft,     // thief steals the paper
        Copying,           // unauthorized photocopy or photo
        Forgery,           // fake alteration of key or QR
        EnvironmentalDam,  // water/fire damage
        BruteForceDecrypt  // cracking BIP-38 passphrase
    }

    /// @notice Defense mechanisms for paper wallets
    enum DefenseType {
        SecureStorage,     // store in a locked safe or deposit box
        Lamination,        // laminate to protect from water/tear
        RedundantBackups,  // multiple independent copies
        MultiFactor,       // combine with PIN or hardware note
        OfflineVerification // verify by offline scanner before use
    }

    struct Term {
        PaperWalletType walletType;
        AttackType      attack;
        DefenseType     defense;
        uint256         timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PaperWalletType walletType,
        AttackType      attack,
        DefenseType     defense,
        uint256         timestamp
    );

    /**
     * @notice Register a new Paper Wallet term.
     * @param walletType The paper wallet implementation type.
     * @param attack     The anticipated attack vector.
     * @param defense    The chosen defense mechanism.
     * @return id        The ID of the newly registered term.
     */
    function registerTerm(
        PaperWalletType walletType,
        AttackType      attack,
        DefenseType     defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            walletType: walletType,
            attack:     attack,
            defense:    defense,
            timestamp:  block.timestamp
        });
        emit TermRegistered(id, walletType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Paper Wallet term.
     * @param id The term ID.
     * @return walletType The paper wallet type.
     * @return attack     The attack vector.
     * @return defense    The defense mechanism.
     * @return timestamp  When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PaperWalletType walletType,
            AttackType      attack,
            DefenseType     defense,
            uint256         timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.walletType, t.attack, t.defense, t.timestamp);
    }
}
