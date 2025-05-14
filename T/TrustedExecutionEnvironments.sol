// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TEEExecutionVerifier - Verifies signed results from a Trusted Execution Environment

interface ISignatureVerifier {
    function verify(bytes32 messageHash, bytes calldata signature, address signer) external pure returns (bool);
}

contract TEEExecutionVerifier {
    address public teeSigner; // Public key of TEE enclave
    ISignatureVerifier public verifier;

    event TrustedComputationVerified(bytes32 indexed resultHash, address verifiedBy);

    constructor(address _verifier, address _teeSigner) {
        verifier = ISignatureVerifier(_verifier);
        teeSigner = _teeSigner;
    }

    function verifyTEEOutput(bytes32 resultHash, bytes calldata signature) external {
        require(verifier.verify(resultHash, signature, teeSigner), "TEE signature invalid");
        emit TrustedComputationVerified(resultHash, msg.sender);
    }
}
