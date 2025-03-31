// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommitmentScheme {
    // Mapping to store commitments of each address.
    mapping(address => bytes32) public commitments;

    // Emitted when a commitment is recorded.
    event CommitmentMade(address indexed committer, bytes32 commitment);

    // Emitted when a commitment is successfully revealed.
    event CommitmentRevealed(address indexed committer, string value, uint256 nonce);

    /// @notice Allows a user to commit to a value by submitting its hash.
    /// @param commitment The hash of the value and nonce (computed as keccak256(abi.encodePacked(value, nonce))).
    function commit(bytes32 commitment) external {
        // Record the commitment for the sender.
        commitments[msg.sender] = commitment;
        emit CommitmentMade(msg.sender, commitment);
    }

    /// @notice Reveals the original value and nonce to prove the commitment.
    /// @param value The original string value.
    /// @param nonce A number used to ensure uniqueness.
    /// @return valid A boolean indicating if the revealed value matches the commitment.
    function reveal(string calldata value, uint256 nonce) external view returns (bool valid) {
        // Compute the hash from the provided value and nonce.
        bytes32 computedHash = keccak256(abi.encodePacked(value, nonce));
        // Check if the computed hash matches the stored commitment.
        valid = (computedHash == commitments[msg.sender]);
        // Note: In an actual application you might want to clear the commitment once it's revealed.
    }
}
