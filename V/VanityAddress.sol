// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VanityGuard - Detects vanity deployers and prevents origin-based spoofing
contract VanityGuard {
    address public immutable deployer;
    string public vanityPrefix;
    mapping(address => bool) public trustedSigners;
    mapping(address => bool) public blacklist;

    event FlaggedVanity(address indexed vanityAddr, string prefix);
    event AuthorizedSigner(address indexed signer);
    event Blacklisted(address indexed attacker);

    constructor(string memory _vanityPrefix) {
        deployer = msg.sender;
        vanityPrefix = _vanityPrefix;

        if (matchesVanity(msg.sender, _vanityPrefix)) {
            emit FlaggedVanity(msg.sender, _vanityPrefix);
        }
    }

    modifier onlyTrustedSigner(bytes32 messageHash, bytes calldata signature) {
        address recovered = recover(messageHash, signature);
        require(trustedSigners[recovered], "Unauthorized signer");
        _;
    }

    function addTrustedSigner(address signer) external {
        require(msg.sender == deployer, "Only deployer");
        trustedSigners[signer] = true;
        emit AuthorizedSigner(signer);
    }

    function blacklistAddress(address attacker) external {
        require(msg.sender == deployer, "Only deployer");
        blacklist[attacker] = true;
        emit Blacklisted(attacker);
    }

    function matchesVanity(address addr, string memory prefix) public pure returns (bool) {
        bytes memory addrBytes = abi.encodePacked(addr);
        bytes memory prefixBytes = bytes(prefix);
        for (uint i = 0; i < prefixBytes.length; i++) {
            if (i >= addrBytes.length || toHexChar(uint8(addrBytes[i] >> 4)) != prefixBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function toHexChar(uint8 nibble) internal pure returns (bytes1) {
        return (nibble < 10)
            ? bytes1(nibble + 0x30)
            : bytes1(nibble + 0x57); // 0x61 - 10 = 'a'
    }

    /// Secure action gated by signer check, not vanity origin
    function secureAction(bytes32 hash, bytes calldata sig) external onlyTrustedSigner(hash, sig) returns (string memory) {
        require(!blacklist[msg.sender], "Blacklisted");
        return "Access Granted: Verified by Signature";
    }

    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "Bad signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(hash, v, r, s);
    }
}
