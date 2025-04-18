// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title OffChainBallotGovernance
 * @notice Voters sign “Ballot(proposalId,choice)” off‑chain. On‑chain you submit
 *         an array of signed ballots; once yes‑votes ≥ threshold, the proposal executes.
 */
contract OffChainBallotGovernance is Ownable, EIP712 {
    using ECDSA for bytes32;

    struct Ballot { uint256 proposalId; bool choice; }

    mapping(address => mapping(uint256 => bool)) public hasVoted;    // voter → proposalId
    mapping(uint256 => bool) public executed;                       // proposalId → done
    uint256 public threshold;
    bytes32 private constant BALLOT_TYPEHASH =
        keccak256("Ballot(uint256 proposalId,bool choice)");

    event ProposalExecuted(uint256 indexed proposalId, address indexed target, bytes data);

    constructor(uint256 _threshold) Ownable(msg.sender) EIP712("OffChainBallotGovernance", "1") {
        require(_threshold > 0, "Threshold>0");
        threshold = _threshold;
    }

    function setThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 0, "Threshold>0");
        threshold = _threshold;
    }

    /**
     * @notice Submit and tally a batch of ballots.
     * @param target      Address to call if proposal passes.
     * @param data        Calldata for execution.
     * @param ballots     Array of Ballot structs.
     * @param signatures Array of ECDSA signatures matching each ballot.
     */
    function submitBallots(
        address target,
        bytes calldata data,
        Ballot[] calldata ballots,
        bytes[] calldata signatures
    ) external {
        require(ballots.length == signatures.length, "Len mismatch");
        uint256 yesCount;
        uint256 pid = ballots[0].proposalId;

        require(!executed[pid], "Already executed");

        for (uint i; i < ballots.length; i++) {
            Ballot calldata b = ballots[i];
            require(b.proposalId == pid, "Mixed proposals");
            require(!hasVoted[_recoverVoter(b, signatures[i])][pid], "Already voted");

            address voter = _recoverVoter(b, signatures[i]);
            hasVoted[voter][pid] = true;
            if (b.choice) yesCount++;
        }

        if (yesCount >= threshold) {
            executed[pid] = true;
            (bool ok, ) = target.call(data);
            require(ok, "Execution failed");
            emit ProposalExecuted(pid, target, data);
        }
    }

    function _recoverVoter(Ballot calldata b, bytes calldata sig) private view returns (address) {
        bytes32 structHash = keccak256(abi.encode(
            BALLOT_TYPEHASH,
            b.proposalId,
            b.choice
        ));
        bytes32 digest = _hashTypedDataV4(structHash);
        return ECDSA.recover(digest, sig);
    }
}
