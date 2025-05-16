// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VerifiableInternetGateway - Combines ZK proof, signature, and DID validation
contract VerifiableInternetGateway {
    address public owner;
    mapping(address => bool) public trustedOracles;
    mapping(address => bool) public verifiedDIDs;
    mapping(bytes32 => bool) public usedProofs;

    event VerifiedAccess(address indexed user, bytes32 indexed proofHash);
    event DIDVerified(address indexed signer, string didURI);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerOracle(address oracle) external onlyOwner {
        trustedOracles[oracle] = true;
    }

    function verifyDID(address signer, string calldata didURI, bytes calldata signature) external {
        bytes32 digest = keccak256(abi.encodePacked(signer, didURI));
        require(recover(digest, signature) == signer, "Invalid DID proof");
        verifiedDIDs[signer] = true;
        emit DIDVerified(signer, didURI);
    }

    function verifyAccess(
        bytes32 zkHash,       // Hash of input to verifier
        bytes calldata zkProof, // zk-SNARK proof
        bytes calldata oracleSig,
        address oracle
    ) external {
        require(trustedOracles[oracle], "Untrusted oracle");
        require(!usedProofs[zkHash], "Proof already used");

        // Mock: Assume zkHash is proof of valid computation (replace with real ZK verifier)
        require(zkHash != bytes32(0), "Invalid ZK proof");

        // Verify oracle signature binds the proof
        bytes32 signedDigest = keccak256(abi.encodePacked(zkHash, msg.sender, block.number));
        require(recover(signedDigest, oracleSig) == oracle, "Invalid oracle signature");

        usedProofs[zkHash] = true;
        emit VerifiedAccess(msg.sender, zkHash);
    }

    function recover(bytes32 digest, bytes memory sig) public pure returns (address) {
        require(sig.length == 65, "Invalid sig length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(digest, v, r, s);
    }
}
