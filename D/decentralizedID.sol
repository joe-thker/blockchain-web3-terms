// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DecentralizedIdentifier
/// @notice Manages decentralized identifiers (DIDs) dynamically and securely.
contract DecentralizedIdentifier is Ownable, ReentrancyGuard {

    struct DIDDocument {
        string did;
        address owner;
        string documentURI; // IPFS or decentralized storage URI
        uint256 updatedAt;
        bool active;
    }

    mapping(string => DIDDocument) private didRegistry;

    // Events
    event DIDRegistered(string indexed did, address indexed owner, string documentURI);
    event DIDUpdated(string indexed did, string newDocumentURI);
    event DIDRevoked(string indexed did);

    constructor() Ownable(msg.sender) {}

    /// @notice Dynamically register a new DID document
    function registerDID(string calldata did, string calldata documentURI) external nonReentrant {
        require(bytes(did).length > 0, "DID required");
        require(bytes(documentURI).length > 0, "Document URI required");
        require(!didRegistry[did].active, "DID already registered");

        didRegistry[did] = DIDDocument({
            did: did,
            owner: msg.sender,
            documentURI: documentURI,
            updatedAt: block.timestamp,
            active: true
        });

        emit DIDRegistered(did, msg.sender, documentURI);
    }

    /// @notice Update existing DID document dynamically
    function updateDID(string calldata did, string calldata newDocumentURI) external nonReentrant {
        DIDDocument storage doc = didRegistry[did];
        require(doc.active, "DID not active");
        require(doc.owner == msg.sender, "Not DID owner");
        require(bytes(newDocumentURI).length > 0, "Document URI required");

        doc.documentURI = newDocumentURI;
        doc.updatedAt = block.timestamp;

        emit DIDUpdated(did, newDocumentURI);
    }

    /// @notice Revoke existing DID dynamically
    function revokeDID(string calldata did) external nonReentrant {
        DIDDocument storage doc = didRegistry[did];
        require(doc.active, "DID not active");
        require(doc.owner == msg.sender, "Not DID owner");

        doc.active = false;

        emit DIDRevoked(did);
    }

    /// @notice Retrieve DID document details
    function resolveDID(string calldata did) external view returns (DIDDocument memory) {
        require(didRegistry[did].active, "DID inactive or not found");
        return didRegistry[did];
    }

    /// @notice Check DID existence and status
    function isActiveDID(string calldata did) external view returns (bool) {
        return didRegistry[did].active;
    }
}
