// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// ------------------------------------------------------------------------
/// 1) Manifest Registration
/// ------------------------------------------------------------------------
contract ManifestRegistry {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    string  public manifestURI;
    uint256 public version;
    bytes32 public checksum;       // keccak256 of manifest contents

    constructor() {
        owner = msg.sender;
    }

    // --- Attack: anyone overwrites URI/version/checksum
    function registerInsecure(string calldata uri, uint256 ver, bytes32 sum) external {
        manifestURI = uri;
        version     = ver;
        checksum    = sum;
    }

    // --- Defense: onlyOwner + monotonic version + checksum verify
    function registerSecure(string calldata uri, uint256 ver, bytes32 sum) external onlyOwner {
        require(ver > version, "Version not higher");
        // In practice you'd fetch and hash off‐chain; here we just store the provided sum
        manifestURI = uri;
        version     = ver;
        checksum    = sum;
    }
}

/// ------------------------------------------------------------------------
/// 2) Data Source Whitelisting
/// ------------------------------------------------------------------------
contract DataSourceRegistry is ReentrancyGuard {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    uint256 public constant MAX_SOURCES = 50;
    address[] public sources;
    mapping(address=>bool) public isWhitelisted;

    constructor() {
        owner = msg.sender;
    }

    // --- Attack: anyone adds unlimited sources
    function addSourceInsecure(address src) external {
        sources.push(src);
        isWhitelisted[src] = true;
    }
    function removeSourceInsecure(address src) external {
        isWhitelisted[src] = false;
        // src remains in list
    }

    // --- Defense: onlyOwner + cap + idempotent add/remove
    function addSourceSecure(address src) external onlyOwner {
        require(sources.length < MAX_SOURCES, "Max sources");
        require(!isWhitelisted[src], "Already added");
        sources.push(src);
        isWhitelisted[src] = true;
    }
    function removeSourceSecure(address src) external onlyOwner {
        require(isWhitelisted[src], "Not present");
        isWhitelisted[src] = false;
        // optionally prune from `sources` array off‐chain
    }
}

/// ------------------------------------------------------------------------
/// 3) Mapping Handler Execution
/// ------------------------------------------------------------------------
contract HandlerExecutor is ReentrancyGuard {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    // insecure: allow any handler
    function executeInsecure(address handler, bytes calldata data) external onlyOwner {
        // no whitelist or code check
        (bool ok, ) = handler.delegatecall(data);
        require(ok, "handler failed");
    }

    // secure: whitelist + codehash + CEI + nonReentrant
    mapping(address=>bytes32) public allowedHandlers; // handler ⇒ extcodehash

    function registerHandler(address handler, bool ok) external onlyOwner {
        if (ok) {
            // store the implementation hash
            bytes32 h; assembly { h := extcodehash(handler) }
            allowedHandlers[handler] = h;
        } else {
            delete allowedHandlers[handler];
        }
    }

    function executeSecure(address handler, bytes calldata data) external onlyOwner nonReentrant {
        bytes32 expected = allowedHandlers[handler];
        require(expected != bytes32(0), "Handler not allowed");
        // verify code hasn't changed
        bytes32 actual; assembly { actual := extcodehash(handler) }
        require(actual == expected, "Codehash mismatch");
        // CEI done: no state changes before this point
        (bool ok, ) = handler.delegatecall(data);
        require(ok, "handler failed");
    }
}
