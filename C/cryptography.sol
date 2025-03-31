// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CryptographyDemo
/// @notice This contract demonstrates cryptographic signature verification in Solidity.
/// It computes the Ethereum signed message hash from a plain text message, recovers the signer
/// using ECDSA (ecrecover), and emits an event if the signature is valid.
contract CryptographyDemo {
    /// @notice Emitted when a signature is successfully verified.
    event SignatureVerified(address indexed signer, string message);

    /// @notice Verifies that a message was signed by the holder of the private key corresponding to the recovered address.
    /// @param message The original message (in plain text).
    /// @param v The recovery identifier.
    /// @param r The first 32 bytes of the signature.
    /// @param s The second 32 bytes of the signature.
    /// @return valid A boolean indicating whether the signature is valid.
    function verifySignature(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool valid) {
        // Compute the hash of the message.
        bytes32 messageHash = keccak256(abi.encodePacked(message));
        
        // Compute the Ethereum Signed Message hash.
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        
        // Recover the address that signed the message.
        address signer = ecrecover(ethSignedMessageHash, v, r, s);
        require(signer != address(0), "Invalid signature");
        
        emit SignatureVerified(signer, message);
        valid = true;
    }
    
    /// @notice Returns the Ethereum Signed Message hash for a given message hash.
    /// @param messageHash The hash of the original message.
    /// @return The hash corresponding to the signed message.
    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        // The "\x19Ethereum Signed Message:\n32" prefix is used by the `eth_sign` JSON-RPC method.
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }
}
