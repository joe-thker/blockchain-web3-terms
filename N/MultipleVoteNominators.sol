// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MultipleVoteNominators
 * @notice A nomination system allowing voters to vote for multiple candidates.
 *         - Each voter can vote once for any given candidate.
 *         - Voters may cast votes for as many candidates as desired.
 *         - The contract tracks individual vote counts and maintains a list of candidates.
 */
contract MultipleVoteNominators {
    address public admin;
    bool public nominationOpen;

    // Mapping from candidate address to vote count.
    mapping(address => uint256) public candidateVotes;
    // Maintain a list of candidate addresses.
    address[] public candidates;
    mapping(address => bool) public candidateExists;

    // Nested mapping to track if a voter has voted for a specific candidate.
    mapping(address => mapping(address => bool)) public hasVotedForCandidate;

    event NominationOpened();
    event NominationClosed();
    event CandidateVoted(address indexed voter, address indexed candidate, uint256 currentVotes);
    event NewCandidateAdded(address indexed candidate);

    constructor() {
        admin = msg.sender;
        nominationOpen = false;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    /**
     * @notice Open the nomination period.
     */
    function openNominations() external onlyAdmin {
        nominationOpen = true;
        emit NominationOpened();
    }

    /**
     * @notice Close the nomination period.
     */
    function closeNominations() external onlyAdmin {
        nominationOpen = false;
        emit NominationClosed();
    }

    /**
     * @notice Vote for a candidate. Each voter can vote for a candidate only once.
     * @param candidate The address of the candidate.
     */
    function voteForCandidate(address candidate) external {
        require(nominationOpen, "Nomination period is not open");
        require(candidate != address(0), "Invalid candidate address");
        require(!hasVotedForCandidate[msg.sender][candidate], "Already voted for this candidate");

        // Mark that the voter has voted for the candidate.
        hasVotedForCandidate[msg.sender][candidate] = true;

        if (!candidateExists[candidate]) {
            candidateExists[candidate] = true;
            candidates.push(candidate);
            // No separate event needed; will be covered in CandidateVoted.
        }

        candidateVotes[candidate] += 1;
        emit CandidateVoted(msg.sender, candidate, candidateVotes[candidate]);
    }

    /**
     * @notice Returns the candidate with the highest number of votes.
     * @return winner The address of the candidate with the most votes.
     */
    function getLeadingCandidate() external view returns (address winner) {
        uint256 highestVotes = 0;
        address currentWinner = address(0);
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidateVotes[candidates[i]] > highestVotes) {
                highestVotes = candidateVotes[candidates[i]];
                currentWinner = candidates[i];
            }
        }
        return currentWinner;
    }

    /**
     * @notice Returns the list of all candidate addresses.
     * @return An array of candidate addresses.
     */
    function getAllCandidates() external view returns (address[] memory) {
        return candidates;
    }
}
