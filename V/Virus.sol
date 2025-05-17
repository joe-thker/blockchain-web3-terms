// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VirusDefense {
    address public immutable owner;
    mapping(address => bool) public knownViruses;

    event AttackBlocked(address indexed attacker);
    event VirusDetected(address indexed clone);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function blockIfVirus(address suspected) external {
        require(isVirus(suspected), "Not virus");
        knownViruses[suspected] = true;
        emit VirusDetected(suspected);
    }

    function safeCall(address target, bytes calldata data) external {
        require(!knownViruses[target], "Blocked: virus detected");
        (bool ok, ) = target.call(data);
        require(ok, "Call failed");
    }

    function isVirus(address suspected) public view returns (bool) {
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(suspected)
        }
        return codeHash == keccak256(type(VirusClone).creationCode); // example hash match
    }
}
