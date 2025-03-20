// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BetaRelease
/// @notice This contract simulates a beta release version of a decentralized application.
/// @dev Features in this beta release are experimental. Users can test the beta feature and submit feedback.
contract BetaRelease {
    // Beta version identifier.
    string public version = "Beta v0.1";
    address public owner;

    // Event emitted when a user submits feedback.
    event FeedbackSubmitted(address indexed user, string feedback);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Updates the beta version. Only callable by the owner.
    /// @param newVersion The new beta version string.
    function updateVersion(string memory newVersion) public onlyOwner {
        version = newVersion;
    }

    /// @notice An experimental beta feature.
    /// @return A string message indicating the beta feature.
    function betaFeature() public pure returns (string memory) {
        return "This is an experimental beta feature.";
    }

    /// @notice Allows users to submit feedback on the beta release.
    /// @param feedback The feedback string provided by the user.
    function submitFeedback(string memory feedback) public {
        emit FeedbackSubmitted(msg.sender, feedback);
    }
}
