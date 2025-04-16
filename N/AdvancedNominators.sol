// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AdvancedNominators
 * @notice A nomination system that allows voters to update or cancel their vote.
 *         - Each voter can have only one active vote.
 *         - Voters can change their nomination while the nomination period is open.
 *         - When a vote is updated, the previous candidate's vote count is decremented.
 */
contract AdvancedNominators {
    address public admin;
    bool public nominationOpen;

    // Mapping from candidate address to vote count.
    mapping(address => uint256) public candidateVotes;
    // Keep track of all candidate addresses.
    address[] public candidates;
    mapping(address => bool) public candidateExists;

    // Mapping to store the candidate voted for by each voter.
    mapping(address => address) public voterChoice;

    event NominationOpened();
    event NominationClosed();
    event VoteUpdated(address indexed voter, address indexed oldCandidate, address indexed newCandidate);
    event VoteCanceled(address indexed voter, address indexed candidate);
    event CandidateNominated(address indexed voter, address indexed candidate, uint256 currentVotes);
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
     * @notice Cast or update a vote for a candidate.
     *         If the voter has already voted, the vote is updated (old vote removed).
     * @param candidate The address of the candidate.
     */
    function nominateCandidate(address candidate) external {
        require(nominationOpen, "Nomination period is not open");
        require(candidate != address(0), "Invalid candidate address");

        // If voter has voted before, update vote counts.
        if (voterChoice[msg.sender] != address(0)) {
            address oldCandidate = voterChoice[msg.sender];
            // If the new candidate is the same as the old one, do nothing.
            require(oldCandidate != candidate, "Already voted for this candidate");
            // Reduce vote count for previous candidate.
            candidateVotes[oldCandidate] -= 1;
            emit VoteUpdated(msg.sender, oldCandidate, candidate);
        } else {
            emit CandidateNominated(msg.sender, candidate, candidateVotes[candidate] + 1);
        }

        voterChoice[msg.sender] = candidate;
        if (!candidateExists[candidate]) {
            candidateExists[candidate] = true;
            candidates.push(candidate);
            // No separate event for new candidate since VoteUpdated or CandidateNominated covers it.
        }
        candidateVotes[candidate] += 1;
    }

    /**
     * @notice Cancel an active vote.
     */
    function cancelVote() external {
        require(nominationOpen, "Nomination period is not open");
        address candidate = voterChoice[msg.sender];
        require(candidate != address(0), "No active vote to cancel");

        candidateVotes[candidate] -= 1;
        emit VoteCanceled(msg.sender, candidate);

        // Remove voter's active choice.
        voterChoice[msg.sender] = address(0);
    }

    /**
     * @notice Returns the candidate with the highest number of votes.
     * @return winner The address of the leading candidate.
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
     * @notice Returns the list of candidate addresses.
     * @return An array of candidate addresses.
     */
    function getAllCandidates() external view returns (address[] memory) {
        return candidates;
    }
}
