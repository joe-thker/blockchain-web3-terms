// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Nominators
 * @notice A smart contract that implements a simple nomination system.
 *         The admin can open/close the nomination period, and each
 *         voter (nominator) may cast one vote for a candidate.
 *         The contract tracks each candidate’s vote count and provides
 *         a helper function to view the current leading candidate.
 */
contract Nominators {
    // Admin address that controls the nomination period.
    address public admin;
    // Flag to indicate if the nomination period is open.
    bool public nominationOpen;

    // Mapping from candidate address to number of votes received.
    mapping(address => uint256) public candidateVotes;
    // Mapping to check if a candidate is already recorded in the candidates list.
    mapping(address => bool) public candidateExists;
    // Array holding the list of candidate addresses.
    address[] public candidates;

    // Mapping to track if a voter (nominator) has already cast their vote.
    mapping(address => bool) public hasVoted;

    // Events for logging significant actions.
    event NominationOpened();
    event NominationClosed();
    event CandidateNominated(address indexed voter, address indexed candidate, uint256 currentVotes);
    event NewCandidateAdded(address indexed candidate);

    /**
     * @dev Constructor sets the deployer as the admin and initializes nomination as closed.
     */
    constructor() {
        admin = msg.sender;
        nominationOpen = false;
    }

    /**
     * @notice Opens the nomination period. Only the admin can call this.
     */
    function openNominations() external onlyAdmin {
        nominationOpen = true;
        emit NominationOpened();
    }

    /**
     * @notice Closes the nomination period. Only the admin can call this.
     */
    function closeNominations() external onlyAdmin {
        nominationOpen = false;
        emit NominationClosed();
    }

    /**
     * @notice Casts a vote by nominating a candidate.
     *         Each voter may vote only once during an open nomination period.
     * @param candidate The address of the candidate being nominated.
     */
    function nominateCandidate(address candidate) external {
        require(nominationOpen, "Nomination period is not open");
        require(!hasVoted[msg.sender], "You have already cast your vote");
        require(candidate != address(0), "Invalid candidate address");

        // Mark the voter as having voted.
        hasVoted[msg.sender] = true;

        // If the candidate is new, add to the list.
        if (!candidateExists[candidate]) {
            candidateExists[candidate] = true;
            candidates.push(candidate);
            emit NewCandidateAdded(candidate);
        }

        // Increment the candidate's vote count.
        candidateVotes[candidate] += 1;
        emit CandidateNominated(msg.sender, candidate, candidateVotes[candidate]);
    }

    /**
     * @notice Returns the candidate with the highest number of votes.
     *         If no candidate is nominated, returns address(0).
     * @return winner The address of the candidate with the most votes.
     */
    function getLeadingCandidate() external view returns (address winner) {
        uint256 highestVotes = 0;
        address currentWinner = address(0);

        for (uint256 i = 0; i < candidates.length; i++) {
            address candidate = candidates[i];
            uint256 votes = candidateVotes[candidate];
            if (votes > highestVotes) {
                highestVotes = votes;
                currentWinner = candidate;
            }
        }
        return currentWinner;
    }

    /**
     * @notice Returns the list of all candidate addresses.
     * @return List of candidate addresses.
     */
    function getAllCandidates() external view returns (address[] memory) {
        return candidates;
    }

    /**
     * @dev Modifier to restrict functions to the admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
}
