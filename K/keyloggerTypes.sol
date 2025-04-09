// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Keylogger Threat Reporting Registry
/// @notice Simulates user-side logging of different keylogger threats (for security dashboards, user profiling, or alerts)
contract KeyloggerThreatRegistry {
    enum KeyloggerType {
        SoftwareBased,
        HardwareBased,
        WebJSBased,
        ClipboardLogger,
        KernelLevel,
        SmartphoneApp,
        CloudBased,
        BIOSFirmware
    }

    struct Report {
        address reporter;
        KeyloggerType keyloggerType;
        string notes;
        uint256 timestamp;
    }

    event KeyloggerReported(
        address indexed reporter,
        KeyloggerType keyloggerType,
        string notes,
        uint256 timestamp
    );

    mapping(address => Report[]) private userReports;

    /// @notice Submit a report of a suspected keylogger activity
    function reportKeylogger(KeyloggerType _type, string calldata _notes) external {
        require(bytes(_notes).length > 3, "More detailed note required");

        Report memory newReport = Report({
            reporter: msg.sender,
            keyloggerType: _type,
            notes: _notes,
            timestamp: block.timestamp
        });

        userReports[msg.sender].push(newReport);

        emit KeyloggerReported(msg.sender, _type, _notes, block.timestamp);
    }

    /// @notice View all reports submitted by a user
    function getUserReports(address _user) external view returns (Report[] memory) {
        return userReports[_user];
    }
}
