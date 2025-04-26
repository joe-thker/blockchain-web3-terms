// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PhonePhishingRegistry
 * @notice Defines “Phone Phishing” subtypes along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PhonePhishingRegistry {
    /// @notice Subtypes of phone-based phishing
    enum PhonePhishingType {
        Vishing,         // voice call impersonation
        SMiShing,        // SMS text phishing
        SpearVishing,    // targeted voice phishing
        Whaling,         // high-value target phishing
        RoboCallPhishing // automated robocall phishing
    }

    /// @notice Specific attack vectors in phone phishing
    enum AttackType {
        CallerIDSpoofing,    // forging the caller ID
        SocialEngineering,   // manipulating victim via conversation
        MalwareLinkSMS,      // sending malicious links via SMS
        CredentialHarvest,   // coaxing victim to reveal credentials
        VoicemailTrap        // leaving phishing voicemail messages
    }

    /// @notice Defense mechanisms against phone phishing
    enum DefenseType {
        UserEducation,       // training to recognize phishing
        MultiFactorAuth,     // requiring second-factor approval
        CallBlocking,        // blocking known spam numbers
        SMSSpamFilter,       // filtering malicious SMS messages
        NumberVerification   // verifying caller identity separately
    }

    struct Term {
        PhonePhishingType phishingType;
        AttackType        attack;
        DefenseType       defense;
        uint256           timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed id,
        PhonePhishingType phishingType,
        AttackType        attack,
        DefenseType       defense,
        uint256           timestamp
    );

    /**
     * @notice Register a new Phone Phishing term.
     * @param phishingType The subtype of phone phishing.
     * @param attack       The anticipated attack vector.
     * @param defense      The chosen defense mechanism.
     * @return id          The ID of the newly registered term.
     */
    function registerTerm(
        PhonePhishingType phishingType,
        AttackType        attack,
        DefenseType       defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            phishingType: phishingType,
            attack:       attack,
            defense:      defense,
            timestamp:    block.timestamp
        });
        emit TermRegistered(id, phishingType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered Phone Phishing term.
     * @param id The term ID.
     * @return phishingType The phone phishing subtype.
     * @return attack       The attack vector.
     * @return defense      The defense mechanism.
     * @return timestamp    When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            PhonePhishingType phishingType,
            AttackType        attack,
            DefenseType       defense,
            uint256           timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.phishingType, t.attack, t.defense, t.timestamp);
    }
}
