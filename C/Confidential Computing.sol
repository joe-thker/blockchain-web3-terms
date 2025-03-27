// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ConfidentialComputing
/// @notice This contract allows users to submit confidential computation jobs.
/// Each job includes encrypted input data and a commitment hash. A trusted TEE operator
/// later reports the result (encrypted output) and marks the job as completed or failed.
/// The contract uses Ownable and ReentrancyGuard for security.
contract ConfidentialComputing is Ownable, ReentrancyGuard {
    /// @notice JobStatus represents the current state of a computation job.
    enum JobStatus { Pending, Completed, Failed }

    /// @notice A Job stores all the details related to a confidential computing task.
    struct Job {
        uint256 id;
        address submitter;
        bytes encryptedInput;   // The encrypted input data
        bytes32 commitment;     // A commitment hash for verifying input or expected output
        JobStatus status;
        bytes encryptedOutput;  // The encrypted result after computation (set by TEE)
        uint256 timestamp;      // Time of job submission
    }

    uint256 public nextJobId;
    /// @notice Mapping from job id to the Job details.
    mapping(uint256 => Job) public jobs;

    /// @notice Address of the trusted TEE operator that is authorized to report job results.
    address public trustedTEE;

    /// @notice Emitted when a new job is submitted.
    event JobSubmitted(uint256 indexed jobId, address indexed submitter, bytes32 commitment);
    /// @notice Emitted when a job is successfully completed.
    event JobCompleted(uint256 indexed jobId, address indexed submitter, bytes32 commitment);
    /// @notice Emitted when a job fails.
    event JobFailed(uint256 indexed jobId, address indexed submitter);
    /// @notice Emitted when the trusted TEE operator is updated.
    event TrustedTEEUpdated(address indexed newTrustedTEE);

    /// @notice Constructor sets the initial trusted TEE operator.
    /// @param _trustedTEE Address of the trusted TEE operator.
    constructor(address _trustedTEE) Ownable(msg.sender) {
        require(_trustedTEE != address(0), "Invalid TEE operator address");
        trustedTEE = _trustedTEE;
    }

    /// @notice Allows the owner to update the trusted TEE operator.
    /// @param _trustedTEE Address of the new trusted TEE operator.
    function updateTrustedTEE(address _trustedTEE) external onlyOwner {
        require(_trustedTEE != address(0), "Invalid TEE operator address");
        trustedTEE = _trustedTEE;
        emit TrustedTEEUpdated(_trustedTEE);
    }

    /// @notice Submits a new confidential computing job.
    /// @param encryptedInput The encrypted input data.
    /// @param commitment A commitment hash (e.g., hash of the expected output).
    /// @return jobId The unique identifier of the submitted job.
    function submitJob(bytes calldata encryptedInput, bytes32 commitment)
        external
        nonReentrant
        returns (uint256 jobId)
    {
        jobId = nextJobId;
        nextJobId++;

        jobs[jobId] = Job({
            id: jobId,
            submitter: msg.sender,
            encryptedInput: encryptedInput,
            commitment: commitment,
            status: JobStatus.Pending,
            encryptedOutput: "",
            timestamp: block.timestamp
        });

        emit JobSubmitted(jobId, msg.sender, commitment);
    }

    /// @notice Reports the result of a confidential computing job.
    /// Only the trusted TEE operator can call this function.
    /// @param jobId The identifier of the job.
    /// @param encryptedOutput The encrypted result data.
    /// @param success A boolean indicating whether the computation succeeded.
    function reportJobResult(
        uint256 jobId,
        bytes calldata encryptedOutput,
        bool success
    ) external nonReentrant {
        require(msg.sender == trustedTEE, "Only trusted TEE can report results");
        Job storage job = jobs[jobId];
        require(job.status == JobStatus.Pending, "Job is not pending");

        if (success) {
            job.status = JobStatus.Completed;
            job.encryptedOutput = encryptedOutput;
            emit JobCompleted(jobId, job.submitter, job.commitment);
        } else {
            job.status = JobStatus.Failed;
            emit JobFailed(jobId, job.submitter);
        }
    }

    /// @notice Retrieves the details of a specific job.
    /// @param jobId The identifier of the job.
    /// @return The Job struct associated with the given jobId.
    function getJob(uint256 jobId) external view returns (Job memory) {
        return jobs[jobId];
    }
}
