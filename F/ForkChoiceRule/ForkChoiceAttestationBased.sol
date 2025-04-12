// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ForkChoiceAttestationBased {
    mapping(bytes32 => uint256) public attestations;
    bytes32 public canonical;

    event Attested(bytes32 indexed forkId, uint256 totalVotes);
    event CanonicalForkChanged(bytes32 forkId);

    function attest(bytes32 forkId) external payable {
        require(msg.value > 0, "Must send ETH as attestation weight");
        attestations[forkId] += msg.value;

        if (attestations[forkId] > attestations[canonical]) {
            canonical = forkId;
            emit CanonicalForkChanged(forkId);
        }

        emit Attested(forkId, attestations[forkId]);
    }

    function getCanonical() external view returns (bytes32) {
        return canonical;
    }
}
