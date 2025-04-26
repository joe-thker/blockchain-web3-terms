// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PlatformRegistry
 * @notice Defines “Platform” categories along with common attack vectors
 *         and defense mechanisms. Users can register and query these
 *         combinations on-chain for analysis or governance.
 */
contract PlatformRegistry {
    /// @notice Types of platforms
    enum PlatformType {
        WebApp,            // traditional web application
        MobileApp,         // smartphone or tablet app
        DesktopApp,        // installed desktop software
        DecentralizedApp,  // on-chain dApp
        CloudService,      // cloud-hosted platform
        IoTPlatform        // Internet-of-Things gateway/platform
    }

    /// @notice Attack vectors targeting platforms
    enum AttackType {
        SQLInjection,      // injecting malicious SQL queries
        CrossSiteScripting,// XSS in web inputs
        DDoS,              // denial-of-service flooding
        Phishing,          // tricking users into disclosing credentials
        Ransomware         // encrypting data for ransom
    }

    /// @notice Defense mechanisms for platforms
    enum DefenseType {
        WAF,               // web application firewall
        RateLimiting,      // request throttling
        InputValidation,   // sanitizing and validating inputs
        MultiFactorAuth,   // require MFA on login/actions
        PatchManagement    // timely security patching
    }

    struct Term {
        PlatformType platform;
        AttackType   attack;
        DefenseType  defense;
        uint256      timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PlatformType platform,
        AttackType   attack,
        DefenseType  defense,
        uint256      timestamp
    );

    /**
     * @notice Register a new Platform term.
     * @param platform The category of the platform.
     * @param attack   The anticipated attack vector.
     * @param defense  The chosen defense mechanism.
     * @return id      The ID of the newly registered term.
     */
    function registerTerm(
        PlatformType platform,
        AttackType   attack,
        DefenseType  defense
    )
        external
        returns (uint256 id)
    {
        id = nextId++;
        terms[id] = Term({
            platform:  platform,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, platform, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Platform term.
     * @param id The term ID.
     * @return platform  The platform category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PlatformType platform,
            AttackType   attack,
            DefenseType  defense,
            uint256      timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.platform, t.attack, t.defense, t.timestamp);
    }
}
