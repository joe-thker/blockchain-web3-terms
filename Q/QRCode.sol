// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QRCodeRegistry
 * @notice Defines “QR Code” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract QRCodeRegistry {
    /// @notice Types of QR code uses
    enum QRCodeType {
        PaymentURL,         // QR encoding payment links (e.g., bitcoin: URI)
        Authentication,     // QR for login or 2FA (e.g., TOTP secrets)
        DataSharing,        // QR for sharing arbitrary data/text
        ProductTag,         // QR printed on products for info or tracking
        DynamicQRCode       // server‐generated QR with mutable payload
    }

    /// @notice Attack vectors targeting QR code usage
    enum AttackType {
        Phishing,           // malicious QR leading to fake sites
        Tampering,          // replacing QR labels with malicious codes
        BadURIInjection,    // embedding dangerous URIs or scripts
        Sniffing,           // intercepting dynamic QR data in transit
        SocialEngineering   // tricking users to scan malicious QR
    }

    /// @notice Defense mechanisms for secure QR code use
    enum DefenseType {
        URIValidation,      // whitelist/validate scanned URIs
        HTTPSOnly,          // enforce HTTPS links in QR payloads
        ContentScanning,    // scan payload for malicious patterns
        RateLimiting,       // throttle dynamic QR generation/usage
        UserConfirmation    // require explicit user approval before action
    }

    struct Term {
        QRCodeType  qrType;
        AttackType  attack;
        DefenseType defense;
        uint256     timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        QRCodeType  qrType,
        AttackType  attack,
        DefenseType defense,
        uint256     timestamp
    );

    /**
     * @notice Register a new QR Code term.
     * @param qrType   The QR code usage category.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        QRCodeType  qrType,
        AttackType  attack,
        DefenseType defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            qrType:    qrType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, qrType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered QR Code term.
     * @param id The term ID.
     * @return qrType    The QR code usage category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            QRCodeType  qrType,
            AttackType  attack,
            DefenseType defense,
            uint256     timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.qrType, t.attack, t.defense, t.timestamp);
    }
}
