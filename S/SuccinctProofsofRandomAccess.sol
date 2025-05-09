// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SPoRA Suite
/// @notice 1) SingleProofVerifier, 2) ProofReplayGuard, 3) VerifierKeyManager

interface IVerifier {
    /// @dev returns true if proof is valid for (dataRoot, index, value)
    function verify(
        bytes32 dataRoot,
        uint256 index,
        bytes calldata proof,
        bytes32 value
    ) external view returns (bool);
}

contract SingleProofVerifier {
    IVerifier public verifier;
    bytes32    public dataRoot;

    constructor(address _verifier, bytes32 _root) {
        verifier = IVerifier(_verifier);
        dataRoot = _root;
    }

    // --- Insecure: accept any proof without calling verifier
    function checkProofInsecure(
        uint256 index,
        bytes calldata proof,
        bytes32 value
    ) external pure returns (bool) {
        // no crypto check ⇒ always “valid”
        return true;
    }

    // --- Secure: perform actual on-chain verify call
    function checkProofSecure(
        uint256 index,
        bytes calldata proof,
        bytes32 value
    ) external view returns (bool) {
        // requires the external verifier implements the proof system (e.g. PLONK, STARK)
        return verifier.verify(dataRoot, index, proof, value);
    }
}

contract ProofReplayGuard {
    IVerifier public verifier;
    bytes32    public dataRoot;
    mapping(bytes32 => bool) public usedNullifier;

    constructor(address _verifier, bytes32 _root) {
        verifier = IVerifier(_verifier);
        dataRoot = _root;
    }

    // --- Insecure: accept proof repeatedly
    function redeemInsecure(
        uint256 index,
        bytes calldata proof,
        bytes32 value,
        bytes32 nullifier
    ) external {
        require(verifier.verify(dataRoot, index, proof, value), "Invalid proof");
        // reward logic...
    }

    // --- Secure: prevent replay via nullifier
    function redeemSecure(
        uint256 index,
        bytes calldata proof,
        bytes32 value,
        bytes32 nullifier
    ) external {
        require(!usedNullifier[nullifier], "Proof already used");
        require(verifier.verify(dataRoot, index, proof, value), "Invalid proof");
        usedNullifier[nullifier] = true;
        // reward logic...
    }
}

contract VerifierKeyManager {
    address public owner;
    IVerifier public verifier;
    uint256 public version;
    bytes32 public expectedKeyHash;

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    constructor(address _verifier, bytes32 _keyHash) {
        owner            = msg.sender;
        verifier         = IVerifier(_verifier);
        expectedKeyHash  = _keyHash;
        version          = 1;
    }

    // --- Insecure: anyone can set verifier and break proof checks
    function updateVerifierInsecure(address newVerifier) external {
        verifier = IVerifier(newVerifier);
    }

    // --- Secure: onlyOwner, monotonic version, and checksum verify
    function updateVerifierSecure(address newVerifier, bytes32 newKeyHash) external onlyOwner {
        require(newKeyHash == keccak256(abi.encodePacked(newVerifier)), "Key checksum mismatch");
        version++;
        verifier = IVerifier(newVerifier);
        expectedKeyHash = newKeyHash;
    }
}
