// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TokenizedIdentityModule - Soulbound Identity Token + Credential Revocation + Issuer Control

// ==============================
// 🪪 Soulbound Identity Token (SBT)
// ==============================
contract SoulboundID {
    string public name = "SoulboundIdentity";
    string public symbol = "SBT";

    address public issuer;
    uint256 public nextId;
    mapping(uint256 => address) public ownerOf;
    mapping(address => bool) public hasSBT;

    modifier onlyIssuer() {
        require(msg.sender == issuer, "Not issuer");
        _;
    }

    constructor() {
        issuer = msg.sender;
    }

    function mint(address user) external onlyIssuer returns (uint256) {
        require(!hasSBT[user], "Already has SBT");
        uint256 id = nextId++;
        ownerOf[id] = user;
        hasSBT[user] = true;
        return id;
    }

    // Block transferability (non-transferable identity)
    function transferFrom(address, address, uint256) public pure {
        revert("Soulbound: non-transferable");
    }

    function approve(address, uint256) public pure {
        revert("Soulbound: approvals disabled");
    }
}

// ==============================
// 🧾 Identity Issuer (Whitelist Controlled)
// ==============================
contract IdentityIssuer {
    SoulboundID public sbt;
    mapping(address => bool) public isAuthorizedIssuer;
    address public admin;

    constructor(address _sbt) {
        sbt = SoulboundID(_sbt);
        admin = msg.sender;
        isAuthorizedIssuer[msg.sender] = true;
    }

    function setIssuer(address issuer, bool allowed) external {
        require(msg.sender == admin, "Not admin");
        isAuthorizedIssuer[issuer] = allowed;
    }

    function issue(address to) external {
        require(isAuthorizedIssuer[msg.sender], "Not authorized");
        sbt.mint(to);
    }
}

// ==============================
// 🚫 Credential Revoker
// ==============================
contract CredentialRevoker {
    SoulboundID public sbt;
    mapping(address => bool) public revoked;

    constructor(address _sbt) {
        sbt = SoulboundID(_sbt);
    }

    function revoke(address user) external {
        require(msg.sender == sbt.issuer(), "Only issuer");
        revoked[user] = true;
    }

    function isRevoked(address user) external view returns (bool) {
        return revoked[user];
    }
}

// ==============================
// 🔓 Fake Minter (Simulates Unauthorized Mint)
// ==============================
interface ISBT {
    function mint(address) external returns (uint256);
}

contract FakeMinter {
    function exploit(ISBT target, address victim) external {
        target.mint(victim); // should fail if access control works
    }
}
