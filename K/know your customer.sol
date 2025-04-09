// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title KYC Registry using Merkle Hash Verification
contract KYCRegistry {
    mapping(address => bytes32) public userHashes;
    event KYCVerified(address indexed user, bytes32 identityHash);

    /// @notice Store hashed identity for KYCed user (off-chain verified)
    function verifyKYC(bytes32 identityHash) external {
        require(userHashes[msg.sender] == 0x0, "Already verified");
        userHashes[msg.sender] = identityHash;
        emit KYCVerified(msg.sender, identityHash);
    }

    function isKYCed(address user, bytes32 identityHash) external view returns (bool) {
        return userHashes[user] == identityHash;
    }
}
