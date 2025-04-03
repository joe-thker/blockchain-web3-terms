// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DYORRegistry
/// @notice A dynamic and optimized registry for "Do Your Own Research" submissions.
/// Users can record their research by submitting a URL (or IPFS hash) along with a note,
/// update their submission, or remove it if desired.
contract DYORRegistry is ReentrancyGuard {
    /// @notice Structure representing a research submission.
    struct ResearchSubmission {
        string url;         // URL or IPFS hash pointing to the research document
        string note;        // A note or description of the research
        uint256 timestamp;  // When the submission was made or last updated
        bool active;        // Whether the submission is active
    }

    /// @notice Mapping from user address to their research submission.
    mapping(address => ResearchSubmission) public submissions;

    // --- Events ---
    event SubmissionCreated(address indexed user, string url, string note, uint256 timestamp);
    event SubmissionUpdated(address indexed user, string newUrl, string newNote, uint256 timestamp);
    event SubmissionRemoved(address indexed user, uint256 timestamp);

    /// @notice Creates a new research submission.
    /// @param url The URL (or IPFS hash) pointing to the research document.
    /// @param note A note describing the research.
    function createSubmission(string calldata url, string calldata note)
        external
        nonReentrant
    {
        require(!submissions[msg.sender].active, "Submission already exists");
        require(bytes(url).length > 0, "URL cannot be empty");
        require(bytes(note).length > 0, "Note cannot be empty");

        submissions[msg.sender] = ResearchSubmission({
            url: url,
            note: note,
            timestamp: block.timestamp,
            active: true
        });

        emit SubmissionCreated(msg.sender, url, note, block.timestamp);
    }

    /// @notice Updates an existing research submission.
    /// @param newUrl The new URL (or IPFS hash) for the research document.
    /// @param newNote The new note describing the research.
    function updateSubmission(string calldata newUrl, string calldata newNote)
        external
        nonReentrant
    {
        require(submissions[msg.sender].active, "No active submission to update");
        require(bytes(newUrl).length > 0, "URL cannot be empty");
        require(bytes(newNote).length > 0, "Note cannot be empty");

        ResearchSubmission storage sub = submissions[msg.sender];
        sub.url = newUrl;
        sub.note = newNote;
        sub.timestamp = block.timestamp;

        emit SubmissionUpdated(msg.sender, newUrl, newNote, block.timestamp);
    }

    /// @notice Removes (deactivates) the caller's research submission.
    function removeSubmission() external nonReentrant {
        require(submissions[msg.sender].active, "No active submission to remove");
        submissions[msg.sender].active = false;
        emit SubmissionRemoved(msg.sender, block.timestamp);
    }
}
