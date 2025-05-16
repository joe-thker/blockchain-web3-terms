// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ValidatorGate - Signature and validator-based access control
contract ValidatorGate {
    address public owner;
    uint256 public expirationDelay = 5 minutes;
    mapping(address => bool) public isValidator;
    mapping(bytes32 => bool) public usedDigests;

    event ValidatorAdded(address validator);
    event ValidatorRemoved(address validator);
    event PayloadValidated(address indexed user, bytes32 digest);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address[] memory initialValidators) {
        owner = msg.sender;
        for (uint i = 0; i < initialValidators.length; i++) {
            isValidator[initialValidators[i]] = true;
        }
    }

    function addValidator(address validator) external onlyOwner {
        isValidator[validator] = true;
        emit ValidatorAdded(validator);
    }

    function removeValidator(address validator) external onlyOwner {
        isValidator[validator] = false;
        emit ValidatorRemoved(validator);
    }

    /// @notice Secure validation check with replay protection and expiry
    function validate(
        bytes32 payloadHash,
        uint256 timestamp,
        bytes calldata signature
    ) external returns (bool) {
        require(block.timestamp <= timestamp + expirationDelay, "Expired signature");

        bytes32 digest = keccak256(abi.encodePacked(payloadHash, timestamp));
        require(!usedDigests[digest], "Digest already used");
        usedDigests[digest] = true;

        address signer = recoverSigner(digest, signature);
        require(isValidator[signer], "Invalid signer");

        emit PayloadValidated(signer, digest);
        return true;
    }

    function recoverSigner(bytes32 digest, bytes memory sig) public pure returns (address) {
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

    /// Optional utility to check digest before sending
    function computeDigest(bytes32 payloadHash, uint256 timestamp) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(payloadHash, timestamp));
    }
}
