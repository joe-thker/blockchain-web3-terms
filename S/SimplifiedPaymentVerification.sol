// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SPVSuite
/// @notice Implements MerkleInclusion, HeaderChain, and UTXOProof modules
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// @dev Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

/// 1) Merkle Proof Inclusion
contract MerkleInclusion is Base {
    bytes32 public merkleRoot;
    uint public maxDepth = 32;

    // --- Attack: naive hashing order + no length checks
    function verifyInsecure(bytes32 leaf, bytes32[] calldata proof) external view returns (bool) {
        bytes32 hash = leaf;
        for (uint i = 0; i < proof.length; i++) {
            // always left-concat → vulnerable to ordering attacks
            hash = keccak256(abi.encodePacked(hash, proof[i]));
        }
        return hash == merkleRoot;
    }

    // --- Defense: enforce proof length + sorted‐pair hashing + root match
    function verifySecure(bytes32 leaf, bytes32[] calldata proof) external view returns (bool) {
        uint len = proof.length;
        require(len > 0 && len <= maxDepth, "Bad proof length");
        bytes32 hash = leaf;
        for (uint i = 0; i < len; i++) {
            bytes32 p = proof[i];
            if (hash < p) {
                hash = keccak256(abi.encodePacked(hash, p));
            } else {
                hash = keccak256(abi.encodePacked(p, hash));
            }
        }
        return hash == merkleRoot;
    }

    function setRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
}

/// 2) Header Chain Verification
contract HeaderChain is Base {
    struct Header { bytes32 prevHash; uint256 timestamp; uint32 difficulty; }
    mapping(bytes32 => Header) public headers;
    bytes32 public head;
    uint256 public maxTimeDrift = 2 hours;

    // --- Attack: accept header with wrong prevHash or timestamp rollback
    function addHeaderInsecure(bytes32 hash, bytes32 prev, uint256 ts, uint32 diff) external {
        headers[hash] = Header(prev, ts, diff);
        head = hash;
    }

    // --- Defense: enforce linkage, monotonic timestamp, and difficulty bounds
    function addHeaderSecure(bytes32 hash, bytes32 prev, uint256 ts, uint32 diff) external onlyOwner {
        require(prev == head, "Bad prevHash");
        Header storage parent = headers[prev];
        require(ts > parent.timestamp, "Timestamp not increasing");
        require(ts <= block.timestamp + maxTimeDrift, "Timestamp too far");
        // stub difficulty check: diff within ±10% of parent
        uint32 pd = parent.difficulty;
        require(diff >= pd * 9 / 10 && diff <= pd * 11 / 10, "Bad difficulty");
        headers[hash] = Header(prev, ts, diff);
        head = hash;
    }

    // Initialize genesis
    function initGenesis(bytes32 hash, uint256 ts, uint32 diff) external onlyOwner {
        headers[hash] = Header(bytes32(0), ts, diff);
        head = hash;
    }
}

/// 3) UTXO Proof & Double‐Spend Prevention
contract UTXOProof is Base, ReentrancyGuard {
    MerkleInclusion public merkle;
    uint256 public maxUTXO = 1e18; // max 1 token per UTXO
    mapping(bytes32 => bool) public spent; // nullifier = keccak(txid,index)

    constructor(address merkleAddr) {
        merkle = MerkleInclusion(merkleAddr);
    }

    // --- Attack: replay same UTXO; no proof or bounds check
    function claimInsecure(bytes32 txid, uint index, uint amount) external {
        // no replay protection, no proof
        payable(msg.sender).transfer(amount);
    }

    // --- Defense: require inclusion proof + nullifier tracking + bounds
    function claimSecure(
        bytes32 txid,
        uint index,
        uint amount,
        bytes32[] calldata proof,
        bytes32 leaf
    ) external nonReentrant {
        require(amount > 0 && amount <= maxUTXO, "Bad amount");
        bytes32 nullifier = keccak256(abi.encodePacked(txid, index));
        require(!spent[nullifier], "Already spent");
        // leaf should encode (txid, index, amount, recipient)
        require(leaf == keccak256(abi.encodePacked(txid, index, amount, msg.sender)),
                "Bad leaf");
        // verify against current merkle root
        require(merkle.verifySecure(leaf, proof), "Invalid proof");
        spent[nullifier] = true;
        payable(msg.sender).transfer(amount);
    }

    // Fund contract to pay claims
    receive() external payable {}
}
