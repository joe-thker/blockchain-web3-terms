// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SemanticWebSuite
/// @notice Example implementations of RDFStore, OWLManager, and SPARQLInterface
contract SemanticWebSuite {
    // COMMON owner and access-control modifier
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    constructor() {
        owner = msg.sender;
    }
}

// 1) RDF Triple Store
contract RDFStore is SemanticWebSuite {
    struct Triple { string s; string p; string o; }
    Triple[] public triples;
    mapping(bytes32 => bool) public exists;

    // --- Attack: no checks, anyone can spam or inject
    function addTripleInsecure(string calldata s, string calldata p, string calldata o) external {
        bytes32 key = keccak256(abi.encodePacked(s, p, o));
        triples.push(Triple(s,p,o));
        exists[key] = true;
    }

    // --- Defense: validate inputs and restrict to owner
    function addTripleSecure(string calldata s, string calldata p, string calldata o) external onlyOwner {
        require(bytes(s).length > 0 && bytes(p).length > 0 && bytes(o).length > 0, "Empty field");
        bytes32 key = keccak256(abi.encodePacked(s, p, o));
        require(!exists[key], "Already exists");
        triples.push(Triple(s,p,o));
        exists[key] = true;
    }

    // Deletion (only owner) — defense against unauthorized deletion
    function removeTriple(uint index) external onlyOwner {
        require(index < triples.length, "Out of bounds");
        bytes32 key = keccak256(abi.encodePacked(triples[index].s, triples[index].p, triples[index].o));
        // swap‐and‐pop
        triples[index] = triples[triples.length - 1];
        triples.pop();
        exists[key] = false;
    }
}

// 2) OWL Ontology Manager
contract OWLManager is SemanticWebSuite {
    struct ClassDef { string name; string[] parents; }
    mapping(string => ClassDef) public classes;
    mapping(string => bool) public classExists;
    uint public maxDepth = 10;

    // --- Attack: unchecked additions (poisoning)
    function addClassInsecure(string calldata name, string[] calldata parents) external {
        classes[name] = ClassDef(name, parents);
        classExists[name] = true;
    }

    // --- Defense: schema validation + cycle/depth check
    function addClassSecure(string calldata name, string[] calldata parents) external onlyOwner {
        require(!classExists[name], "Class exists");
        // whitelist check: simple regex‐like (no special chars)
        bytes memory nb = bytes(name);
        require(nb.length >= 1 && nb.length <= 64, "Invalid name");
        // check parent existence & depth
        for (uint i = 0; i < parents.length; i++) {
            require(classExists[parents[i]], "Parent missing");
            _checkDepth(parents[i], 1);
        }
        classes[name] = ClassDef(name, parents);
        classExists[name] = true;
    }

    function _checkDepth(string memory cname, uint depth) internal view {
        require(depth <= maxDepth, "Depth overflow");
        for (uint i = 0; i < classes[cname].parents.length; i++) {
            _checkDepth(classes[cname].parents[i], depth + 1);
        }
    }
}

// 3) SPARQL Query Processor
contract SPARQLInterface is SemanticWebSuite {
    RDFStore public store;
    uint public maxResults = 100;
    uint public maxQueryLength = 256;

    constructor(address rdfAddr) {
        store = RDFStore(rdfAddr);
    }

    // --- Attack: naive string parsing allowing injection
    function queryInsecure(string calldata pattern) external view returns (RDFStore.Triple[] memory) {
        // Danger: no input checks
        return _search(pattern);
    }

    // --- Defense: parameter checks & limits
    function querySecure(string calldata pattern) external view returns (RDFStore.Triple[] memory) {
        require(bytes(pattern).length <= maxQueryLength, "Query too long");
        // escape or enforce only alphanumeric + space
        for (uint i = 0; i < bytes(pattern).length; i++) {
            bytes1 c = bytes(pattern)[i];
            require(
                (c >= 0x30 && c <= 0x39) || // 0-9
                (c >= 0x41 && c <= 0x5A) || // A-Z
                (c >= 0x61 && c <= 0x7A) || // a-z
                c == 0x20,                  // space
                "Invalid char"
            );
        }
        RDFStore.Triple[] memory results = _search(pattern);
        require(results.length <= maxResults, "Too many results");
        return results;
    }

    function _search(string memory pat) internal view returns (RDFStore.Triple[] memory) {
        uint count = store.triples().length;
        RDFStore.Triple[] memory temp = new RDFStore.Triple[](count);
        uint idx = 0;
        for (uint i = 0; i < count; i++) {
            RDFStore.Triple memory t = store.triples(i);
            // simple substring match in subject
            if (_contains(t.s, pat)) {
                temp[idx++] = t;
            }
        }
        // shrink to idx
        RDFStore.Triple[] memory out = new RDFStore.Triple[](idx);
        for (uint j = 0; j < idx; j++) out[j] = temp[j];
        return out;
    }

    function _contains(string memory what, string memory where) internal pure returns (bool) {
        bytes memory w = bytes(what);
        bytes memory h = bytes(where);
        if (h.length > w.length) return false;
        for (uint i = 0; i <= w.length - h.length; i++) {
            bool match_ = true;
            for (uint j = 0; j < h.length; j++) {
                if (w[i + j] != h[j]) { match_ = false; break; }
            }
            if (match_) return true;
        }
        return false;
    }
}
