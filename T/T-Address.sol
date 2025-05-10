// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TAddressModule - Simulates T-Address Privacy Attacks and Defenses in Web3

// ==============================
// 🔓 T-Address Metadata Logger (Vulnerable)
// ==============================
contract TAddressMetadataLogger {
    struct Activity {
        address user;
        string action;
        uint256 timestamp;
    }

    Activity[] public logs;

    function publicLog(string memory action) external {
        logs.push(Activity({
            user: msg.sender,
            action: action,
            timestamp: block.timestamp
        }));
    }

    function getLog(uint256 i) external view returns (address, string memory, uint256) {
        Activity memory a = logs[i];
        return (a.user, a.action, a.timestamp);
    }

    function totalLogs() external view returns (uint256) {
        return logs.length;
    }
}

// ==============================
// 🔓 Dusting Attacker Contract
// ==============================
contract DustingAttacker {
    function dust(address target) external payable {
        require(msg.value > 0, "Need ETH");
        payable(target).transfer(msg.value);
    }

    receive() external payable {}
}

// ==============================
// 🔐 ZK Meta-Transaction Relay (Privacy Abstraction)
// ==============================
interface IZkProofVerifier {
    function verify(bytes calldata proof, address destination, bytes calldata data) external view returns (bool);
}

contract ZkMetaRelay {
    address public verifier;

    constructor(address _verifier) {
        verifier = _verifier;
    }

    function relay(bytes calldata proof, address destination, bytes calldata data) external {
        require(IZkProofVerifier(verifier).verify(proof, destination, data), "Invalid proof");
        (bool ok,) = destination.call(data);
        require(ok, "Call failed");
    }
}

// ==============================
// 🔐 Mock ZK Proof Verifier
// ==============================
contract ZkProofVerifier is IZkProofVerifier {
    bytes32 public trustedHash;

    function setTrusted(bytes32 hash) external {
        trustedHash = hash;
    }

    function verify(bytes calldata proof, address destination, bytes calldata data) external view override returns (bool) {
        return keccak256(abi.encodePacked(destination, data)) == trustedHash;
    }
}
