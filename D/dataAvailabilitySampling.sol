// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title DataAvailabilitySampling
/// @notice This contract allows the owner to set a Merkle root representing an off‑chain dataset.
/// Participants submit samples (with sample index, leaf, and Merkle proof) to verify that data is available.
/// The contract tracks the total and valid samples, and once the number of valid samples meets the threshold,
/// the data is considered available.
contract DataAvailabilitySampling is Ownable, ReentrancyGuard {
    // The Merkle root representing the off-chain dataset.
    bytes32 public dataRoot;
    // Total samples submitted.
    uint256 public totalSamples;
    // Count of valid samples.
    uint256 public validSamples;
    // Number of valid samples required to consider the data available.
    uint256 public requiredSamples;

    // Mapping to track if a given sampler has already submitted a sample for a specific index.
    mapping(address => mapping(uint256 => bool)) public sampleSubmitted;

    // --- Events ---
    event DataRootUpdated(bytes32 newDataRoot);
    event RequiredSamplesUpdated(uint256 newRequiredSamples);
    event SampleSubmitted(address indexed sampler, uint256 sampleIndex, bool valid);

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // No additional initialization required.
    }

    /// @notice Sets or updates the Merkle root representing the off-chain dataset.
    /// Resets sample counters when updated.
    /// @param _dataRoot The new Merkle root.
    function updateDataRoot(bytes32 _dataRoot) external onlyOwner {
        dataRoot = _dataRoot;
        totalSamples = 0;
        validSamples = 0;
        emit DataRootUpdated(_dataRoot);
    }

    /// @notice Sets the required number of valid samples.
    /// @param _requiredSamples The number of valid samples needed.
    function updateRequiredSamples(uint256 _requiredSamples) external onlyOwner {
        require(_requiredSamples > 0, "Required samples must be > 0");
        requiredSamples = _requiredSamples;
        emit RequiredSamplesUpdated(_requiredSamples);
    }

    /// @notice Submits a sample for data availability verification.
    /// @param sampleIndex The index of the sample.
    /// @param leaf The hash of the data chunk.
    /// @param proof The Merkle proof that the leaf is in the dataset.
    function submitSample(
        uint256 sampleIndex,
        bytes32 leaf,
        bytes32[] calldata proof
    ) external nonReentrant {
        require(dataRoot != bytes32(0), "Data root not set");
        require(!sampleSubmitted[msg.sender][sampleIndex], "Sample already submitted for this index");

        // Mark the sample as submitted.
        sampleSubmitted[msg.sender][sampleIndex] = true;
        totalSamples++;

        // Verify the provided Merkle proof.
        bool valid = MerkleProof.verify(proof, dataRoot, leaf);
        if (valid) {
            validSamples++;
        }

        emit SampleSubmitted(msg.sender, sampleIndex, valid);
    }

    /// @notice Checks whether the data is considered available based on valid samples.
    /// @return available True if validSamples meets or exceeds requiredSamples.
    function isDataAvailable() external view returns (bool available) {
        available = validSamples >= requiredSamples;
    }
}
