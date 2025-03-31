// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CryptologyDemo
/// @notice Demonstrates cryptographic techniques including a commit–reveal scheme and signature verification.
contract CryptologyDemo {
    // Mapping to store commitments (hashes) by address.
    mapping(address => bytes32) public commitments;
    
    // --- Events ---
    event Committed(address indexed committer, bytes32 commitment);
    event Revealed(address indexed committer, string secret, uint256 nonce, bool valid);
    event SignatureVerified(address indexed signer, string message);

    /// @notice Allows a user to commit to a secret by submitting its hash.
    /// The commitment is computed off-chain as: keccak256(abi.encodePacked(secret, nonce))
    /// @param commitment The hash of the secret and nonce.
    function commit(bytes32 commitment) external {
        commitments[msg.sender] = commitment;
        emit Committed(msg.sender, commitment);
    }

    /// @notice Reveals the secret and nonce to validate the commitment.
    /// @param secret The original secret (e.g., a string).
    /// @param nonce A number used to ensure uniqueness.
    /// @return valid A boolean indicating whether the revealed secret matches the commitment.
    function reveal(string calldata secret, uint256 nonce) external returns (bool valid) {
        // Compute the hash of the secret and nonce.
        bytes32 computedHash = keccak256(abi.encodePacked(secret, nonce));
        valid = (computedHash == commitments[msg.sender]);
        emit Revealed(msg.sender, secret, nonce, valid);
    }

    /// @notice Verifies that a message was signed by the holder of the private key corresponding to the recovered address.
    /// @param message The original message (plain text).
    /// @param v The recovery identifier of the signature.
    /// @param r The first 32 bytes of the signature.
    /// @param s The second 32 bytes of the signature.
    /// @return valid A boolean indicating if the signature is valid.
    function verifySignature(
        string calldata message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool valid) {
        // Compute the hash of the message.
        bytes32 messageHash = keccak256(abi.encodePacked(message));
        // Compute the Ethereum Signed Message hash.
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        // Recover the signer's address.
        address signer = ecrecover(ethSignedMessageHash, v, r, s);
        require(signer != address(0), "Invalid signature");
        valid = true;
        emit SignatureVerified(signer, message);
    }

    /// @notice Returns the Ethereum Signed Message hash for a given message hash.
    /// @param messageHash The hash of the original message.
    /// @return The hash corresponding to the signed message.
    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        // The standard Ethereum signed message prefix.
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }
}
