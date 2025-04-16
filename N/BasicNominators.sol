// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BasicNominators
 * @notice A simple nomination system.
 *         - The admin controls when nominations are open.
 *         - Each address can cast one vote (nominate one candidate).
 *         - Vote counts are recorded per candidate.
 */
contract BasicNominators {
    address public admin;
    bool public nominationOpen;

    // Mapping from candidate address to vote count.
    mapping(address => uint256) public candidateVotes;
    // Maintain a list of candidates.
    address[] public candidates;
    // Track if a candidate has been added already.
    mapping(address => bool) public candidateExists;
    // Track if a voter has already cast their vote.
    mapping(address => bool) public hasVoted;

    event NominationOpened();
    event NominationClosed();
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
     * @notice Cast a vote by nominating a candidate.
     * @param candidate The address of the candidate.
     */
    function nominateCandidate(address candidate) external {
        require(nominationOpen, "Nomination period is not open");
        require(!hasVoted[msg.sender], "You have already cast your vote");
        require(candidate != address(0), "Invalid candidate address");

        hasVoted[msg.sender] = true;

        if (!candidateExists[candidate]) {
            candidateExists[candidate] = true;
            candidates.push(candidate);
            emit NewCandidateAdded(candidate);
        }

        candidateVotes[candidate] += 1;
        emit CandidateNominated(msg.sender, candidate, candidateVotes[candidate]);
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
     * @notice Returns the full list of candidate addresses.
     * @return An array of candidate addresses.
     */
    function getAllCandidates() external view returns (address[] memory) {
        return candidates;
    }
}
