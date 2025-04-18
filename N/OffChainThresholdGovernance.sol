// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title OffChainThresholdGovernance
 * @notice Governors sign off‑chain “Proposal(proposalId,target,callData)”.
 *         Once `threshold` unique valid signatures are collected, anyone can
 *         call `executeProposal` to run the target call on‑chain exactly once.
 */
contract OffChainThresholdGovernance is Ownable, EIP712 {
    using ECDSA for bytes32;

    // role management
    mapping(address => bool) public governors;
    uint256 public threshold;
    mapping(uint256 => bool) public executed;

    // EIP‑712 type hash
    bytes32 private constant PROPOSAL_TYPEHASH =
        keccak256("Proposal(uint256 proposalId,address target,bytes data)");

    event ProposalExecuted(uint256 indexed proposalId, address indexed target, bytes data);

    constructor(
        address[] memory initialGovernors,
        uint256 initialThreshold
    ) Ownable(msg.sender) EIP712("OffChainThresholdGovernance", "1") {
        require(initialThreshold > 0, "Threshold>0");
        threshold = initialThreshold;
        for (uint i; i < initialGovernors.length; i++) {
            governors[initialGovernors[i]] = true;
        }
    }

    function setThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Threshold>0");
        threshold = newThreshold;
    }

    function addGovernor(address gov) external onlyOwner {
        governors[gov] = true;
    }

    function removeGovernor(address gov) external onlyOwner {
        governors[gov] = false;
    }

    /**
     * @notice Execute a proposal once `threshold` unique governor signatures are provided.
     * @param proposalId Unique ID for this proposal.
     * @param target      Contract address to call.
     * @param data        Calldata for the call.
     * @param sigs        Array of ECDSA signatures (r||s||v) by governors.
     */
    function executeProposal(
        uint256 proposalId,
        address target,
        bytes calldata data,
        bytes[] calldata sigs
    ) external {
        require(!executed[proposalId], "Already executed");

        // Build EIP‑712 digest
        bytes32 structHash = keccak256(abi.encode(
            PROPOSAL_TYPEHASH,
            proposalId,
            target,
            keccak256(data)
        ));
        bytes32 digest = _hashTypedDataV4(structHash);

        // Recover and count unique valid signatures
        address[] memory seen = new address[](sigs.length);
        uint valid;
        for (uint i; i < sigs.length; i++) {
            address signer = ECDSA.recover(digest, sigs[i]);
            if (governors[signer]) {
                // ensure uniqueness
                bool dup;
                for (uint j; j < valid; j++) {
                    if (seen[j] == signer) { dup = true; break; }
                }
                if (!dup) {
                    seen[valid++] = signer;
                    if (valid == threshold) break;
                }
            }
        }
        require(valid >= threshold, "Not enough sigs");

        executed[proposalId] = true;
        (bool ok, ) = target.call(data);
        require(ok, "Call failed");

        emit ProposalExecuted(proposalId, target, data);
    }
}
