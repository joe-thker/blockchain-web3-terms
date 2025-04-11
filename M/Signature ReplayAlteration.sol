// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Signature Replay Protection Example
/// @notice Protects against replaying signatures by marking hashes as used
contract SignatureReplayProtection {
    using ECDSA for bytes32;

    mapping(bytes32 => bool) public usedHashes;

    event SignatureExecuted(address indexed signer, bytes32 indexed hash);

    function execute(bytes32 hash, bytes calldata sig) external {
        require(!usedHashes[hash], "Replay detected");

        // Correct usage of toEthSignedMessageHash()
        bytes32 ethSignedHash = hash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(sig);

        usedHashes[hash] = true;

        emit SignatureExecuted(signer, hash);
        // Additional execution logic here
    }
}
