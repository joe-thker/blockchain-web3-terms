// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DistributedPhase
/// @notice A dynamic and optimized contract for managing a set of phases. Participants can be assigned
/// to these phases. The owner can create, remove, or update phases, and also set which phase each participant is in.
contract DistributedPhase is Ownable, ReentrancyGuard {
    /// @notice Represents a phase in the system, identified by an ID, a name, and active status.
    struct Phase {
        uint256 id;       // Unique ID of the phase
        bool active;      // Whether the phase is active or removed
        string name;      // Descriptive name or label for the phase
    }

    // Auto-incremented ID for phases
    uint256 public nextPhaseId;

    // Array storing all phases (including removed). Index = phaseId
    Phase[] public phases;

    // Mapping from participant address => phaseId they are currently in (or 0 if none/invalid).
    // If the assigned phase is removed, the participant remains in that phase ID, but that phase is no longer active.
    mapping(address => uint256) public participantPhase;

    // --- Events ---
    event PhaseCreated(uint256 indexed phaseId, string name);
    event PhaseUpdated(uint256 indexed phaseId, string newName);
    event PhaseRemoved(uint256 indexed phaseId);

    event ParticipantAssigned(address indexed participant, uint256 phaseId);

    /// @notice Constructor sets the deployer as the initial owner (fixing the “no arguments” base constructor issue).
    constructor() Ownable(msg.sender) {}

    /// @notice Creates a new phase with a specified name. Only the owner can create phases.
    /// @param phaseName A descriptive label for the new phase.
    /// @return phaseId The unique ID assigned to the newly created phase.
    function createPhase(string calldata phaseName)
        external
        onlyOwner
        nonReentrant
        returns (uint256 phaseId)
    {
        require(bytes(phaseName).length > 0, "Phase name cannot be empty");
        phaseId = nextPhaseId++;
        phases.push(Phase({
            id: phaseId,
            active: true,
            name: phaseName
        }));

        emit PhaseCreated(phaseId, phaseName);
    }

    /// @notice Updates the name of an existing phase. Only the owner can update phases.
    /// @param phaseId The ID of the phase to update.
    /// @param newName The new name for the phase.
    function updatePhase(uint256 phaseId, string calldata newName)
        external
        onlyOwner
        nonReentrant
    {
        require(phaseId < phases.length, "Phase ID out of range");
        Phase storage ph = phases[phaseId];
        require(ph.active, "Phase already removed");
        require(bytes(newName).length > 0, "New name cannot be empty");

        ph.name = newName;
        emit PhaseUpdated(phaseId, newName);
    }

    /// @notice Removes (marks as inactive) a phase so it cannot be assigned in the future. 
    /// Already assigned participants remain at that phase ID, but that phase is no longer considered active.
    /// @param phaseId The ID of the phase to remove.
    function removePhase(uint256 phaseId) external onlyOwner nonReentrant {
        require(phaseId < phases.length, "Phase ID out of range");
        Phase storage ph = phases[phaseId];
        require(ph.active, "Phase already removed");

        ph.active = false;
        emit PhaseRemoved(phaseId);
    }

    /// @notice Assigns a participant to a specified phase. Only the owner can assign participants.
    /// Even if the phase is inactive, you may set the participant’s phase – handle logic externally if you wish.
    /// @param participant The participant's address.
    /// @param phaseId The ID of the phase to assign the participant to.
    function assignParticipant(address participant, uint256 phaseId)
        external
        onlyOwner
        nonReentrant
    {
        require(participant != address(0), "Invalid participant address");
        require(phaseId < phases.length, "Phase ID out of range");

        participantPhase[participant] = phaseId;
        emit ParticipantAssigned(participant, phaseId);
    }

    /// @notice Returns the total number of phases ever created (including removed).
    /// @return The length of the phases array.
    function totalPhases() external view returns (uint256) {
        return phases.length;
    }

    /// @notice Retrieves phase details by ID.
    /// @param phaseId The ID of the phase to fetch.
    /// @return A Phase struct containing id, active, and name fields.
    function getPhase(uint256 phaseId)
        external
        view
        returns (Phase memory)
    {
        require(phaseId < phases.length, "Phase ID out of range");
        return phases[phaseId];
    }
}
