// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title OffChainGovernance
 * @notice Implements off‑chain governance via EIP‑712‑signed proposals.
 *         A set of governors can sign proposals off‑chain, and any user
 *         can execute a proposal on‑chain by submitting the signed messages
 *         once a signature threshold is met.
 */
contract OffChainGovernance is Ownable, EIP712 {
    using ECDSA for bytes32;

    /// @notice Mapping of governor addresses allowed to sign proposals.
    mapping(address => bool) public governors;
    /// @notice Number of signatures required to execute a proposal.
    uint256 public threshold;
    /// @notice Tracks which proposal IDs have been executed.
    mapping(uint256 => bool) public executed;

    /// @notice Emitted when a proposal is successfully executed.
    event ProposalExecuted(uint256 indexed proposalId, address indexed target, bytes data);

    // EIP‑712 type hash for a Proposal struct
    bytes32 private constant PROPOSAL_TYPEHASH =
        keccak256("Proposal(uint256 proposalId,address target,bytes data)");

    /**
     * @param _initialThreshold Number of signatures required for execution.
     * @param _initialGovernors Addresses granted governor status.
     */
    constructor(uint256 _initialThreshold, address[] memory _initialGovernors)
        Ownable(msg.sender)
        EIP712("OffChainGovernance", "1")
    {
        require(_initialThreshold > 0, "Threshold must be > 0");
        threshold = _initialThreshold;
        for (uint256 i = 0; i < _initialGovernors.length; i++) {
            governors[_initialGovernors[i]] = true;
        }
    }

    /**
     * @notice Update the signature threshold. Only owner.
     * @param _threshold New threshold, must be > 0.
     */
    function setThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 0, "Threshold must be > 0");
        threshold = _threshold;
    }

    /**
     * @notice Add a governor. Only owner.
     * @param gov Address to grant governor role.
     */
    function addGovernor(address gov) external onlyOwner {
        governors[gov] = true;
    }

    /**
     * @notice Remove a governor. Only owner.
     * @param gov Address to revoke governor role.
     */
    function removeGovernor(address gov) external onlyOwner {
        governors[gov] = false;
    }

    /**
     * @notice Execute a proposal once enough off‑chain signatures are provided.
     * @param proposalId Unique ID for the proposal.
     * @param target Address of the contract to call.
     * @param data Calldata for the target call.
     * @param signatures Array of EIP‑712 signatures by governors.
     * @return returnData The data returned by the target call.
     */
    function executeProposal(
        uint256 proposalId,
        address target,
        bytes calldata data,
        bytes[] calldata signatures
    ) external returns (bytes memory returnData) {
        require(!executed[proposalId], "Already executed");
        // Build the EIP‑712 digest
        bytes32 structHash = keccak256(abi.encode(
            PROPOSAL_TYPEHASH,
            proposalId,
            target,
            keccak256(data)
        ));
        bytes32 digest = _hashTypedDataV4(structHash);

        // Verify signatures
        uint256 validSignatures = 0;
        address[] memory seen = new address[](signatures.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = digest.recover(signatures[i]);
            if (governors[signer]) {
                // Ensure each signer is unique
                bool duplicate = false;
                for (uint256 j = 0; j < validSignatures; j++) {
                    if (seen[j] == signer) {
                        duplicate = true;
                        break;
                    }
                }
                if (!duplicate) {
                    seen[validSignatures] = signer;
                    validSignatures++;
                    if (validSignatures == threshold) {
                        break;
                    }
                }
            }
        }
        require(validSignatures >= threshold, "Not enough valid signatures");

        // Mark executed before external call to prevent re‑entrancy
        executed[proposalId] = true;

        // Execute the proposal's target call
        (bool success, bytes memory result) = target.call(data);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(proposalId, target, data);
        return result;
    }
}
