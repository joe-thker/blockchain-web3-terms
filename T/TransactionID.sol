// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TXIDModule - Track, Verify, and Enforce Unique Transaction Identifiers

/// 📓 TXID Registry for Replay Protection
contract TXIDRegistry {
    mapping(bytes32 => bool) public seen;

    event TXIDUsed(bytes32 indexed txid, address executor);

    function markTXID(bytes32 txid) external {
        require(!seen[txid], "TXID already used");
        seen[txid] = true;
        emit TXIDUsed(txid, msg.sender);
    }

    function isUsed(bytes32 txid) external view returns (bool) {
        return seen[txid];
    }
}

/// 🔐 Secure Executor (uses TXID once)
contract SecureExecutor {
    TXIDRegistry public registry;
    address public admin;

    constructor(address _registry) {
        registry = TXIDRegistry(_registry);
        admin = msg.sender;
    }

    function execute(bytes32 txid, bytes calldata payload) external {
        require(msg.sender == admin, "Not admin");
        registry.markTXID(txid);
        (bool ok, ) = address(this).call(payload);
        require(ok, "Execution failed");
    }

    function sampleAction(uint256 x) external pure returns (uint256) {
        return x * 2;
    }
}

/// ✍️ MetaTX Hashed Verifier (Off-chain TXID)
contract MetaTXHashVerifier {
    mapping(address => uint256) public nonce;

    function verifyAndExecute(
        address user,
        address target,
        bytes calldata data,
        bytes calldata sig
    ) external {
        bytes32 txid = keccak256(abi.encodePacked(user, target, data, nonce[user]));
        require(_verify(txid, sig, user), "Bad sig");
        nonce[user]++;
        (bool ok, ) = target.call(data);
        require(ok, "Call failed");
    }

    function _verify(bytes32 hash, bytes memory sig, address signer) internal pure returns (bool) {
        (uint8 v, bytes32 r, bytes32 s) = split(sig);
        bytes32 m = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return ecrecover(m, v, r, s) == signer;
    }

    function split(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "Bad sig");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }
}

/// 🔓 TXID Attacker (Replay / Duplicate Injection)
interface ITXIDRegistry {
    function markTXID(bytes32) external;
}

contract TXIDAttacker {
    function replayTXID(ITXIDRegistry registry, bytes32 txid) external {
        registry.markTXID(txid); // should revert if already used
    }

    function fakeTXID(bytes memory data) external pure returns (bytes32) {
        return keccak256(data); // attempts spoof
    }
}
