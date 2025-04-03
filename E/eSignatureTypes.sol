// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title ESignatureTypesDemo
/// @notice This contract demonstrates three types of signature verification:
/// 1. Standard ECDSA signature verification,
/// 2. Ethereum Signed Message signature verification, and
/// 3. EIP-712 Typed Data signature verification.
contract ESignatureTypesDemo {
    using ECDSA for bytes32;

    /**
     * @notice Verifies a standard ECDSA signature over a raw message hash.
     * @param messageHash The raw message hash that was signed.
     * @param v The recovery identifier (27 or 28).
     * @param r The r component of the signature (32 bytes).
     * @param s The s component of the signature (32 bytes).
     * @return signer The address recovered from the signature.
     */
    function verifyStandardSignature(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (address signer) {
        // Directly recover the signer from the raw messageHash
        signer = ecrecover(messageHash, v, r, s);
    }

    /**
     * @notice Verifies a signature where the signer signed an Ethereum Signed Message.
     * @param messageHash The raw message hash that was signed.
     * @param v The recovery identifier (27 or 28).
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @return signer The address recovered from the prefixed message.
     */
    function verifyEthSignedMessage(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (address signer) {
        // Convert the raw message hash into an Ethereum Signed Message hash
        bytes32 ethSignedHash = messageHash.toEthSignedMessageHash();
        signer = ecrecover(ethSignedHash, v, r, s);
    }

    /**
     * @notice Verifies an EIP-712 typed data signature.
     * @param domainSeparator The domain separator defined in EIP-712.
     * @param structHash The hash of the typed data structure.
     * @param v The recovery identifier (27 or 28).
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @return signer The address recovered from the EIP-712 digest.
     */
    function verifyEIP712Signature(
        bytes32 domainSeparator,
        bytes32 structHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (address signer) {
        // Compute the EIP-712 digest: keccak256("\x19\x01" || domainSeparator || structHash)
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        signer = ecrecover(digest, v, r, s);
    }
}
