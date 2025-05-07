// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SpoonSuite
/// @notice Insecure vs. Secure patterns for signature replay, chain‐checks, and cross‐chain bridge

abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

//////////////////////////////////////////////////////
// 1) Off‐Chain Signature Replay Protection
//////////////////////////////////////////////////////
contract SpoonPermit {
    // insecure: naive permit with no chainId or nonce
    mapping(address => mapping(address=>uint256)) public allowanceInsecure;

    function permitInsecure(
        address owner, address spender, uint256 value,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Expired");
        bytes32 hash = keccak256(abi.encodePacked(owner, spender, value, deadline));
        address signer = ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s
        );
        require(signer == owner, "Bad sig");
        allowanceInsecure[owner][spender] = value;
    }

    // secure: EIP‐712 domain includes chainId + per‐owner nonce
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline,uint256 chainId)");
    mapping(address=>uint256) public nonces;
    mapping(address => mapping(address=>uint256)) public allowanceSecure;

    constructor() {
        uint256 chainId;
        assembly { chainId := chainid() }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SpoonPermit")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function permitSecure(
        address owner, address spender, uint256 value,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Expired");
        uint256 nonce = nonces[owner]++;
        uint256 chainId;
        assembly { chainId := chainid() }
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline, chainId)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signer = ecrecover(digest, v, r, s);
        require(signer == owner, "Invalid permit");
        allowanceSecure[owner][spender] = value;
    }
}

//////////////////////////////////////////////////////
// 2) Chain-Specific Logic Enforcement
//////////////////////////////////////////////////////
contract SpoonChainCheck {
    uint256 public expectedChainId;

    constructor(uint256 _expectedChainId) {
        expectedChainId = _expectedChainId;
    }

    // insecure: no chain check, anyone can call on any network
    function actionInsecure() external pure returns (string memory) {
        return "Action executed";
    }

    // secure: enforce execution only on intended chain
    function actionSecure() external view returns (string memory) {
        require(block.chainid == expectedChainId, "Wrong chain");
        return "Secure action executed on correct chain";
    }
}

//////////////////////////////////////////////////////
// 3) Cross-Chain Bridge Anti-Spoon Abuse
//////////////////////////////////////////////////////
contract SpoonBridge is ReentrancyGuard {
    // insecure: no per-chain tracking => double-claims allowed
    mapping(uint256 => mapping(uint256 => bool)) public claimedInsecure;
    // chainId ⇒ depositId ⇒ claimed

    function withdrawInsecure(uint256 depositId) external {
        require(!claimedInsecure[block.chainid][depositId], "Already claimed");
        claimedInsecure[block.chainid][depositId] = true;
        // release assets...
    }

    // secure: track `(chainId, depositId)` plus include user in nullifier
    mapping(bytes32 => bool) public claimedSecure;

    function withdrawSecure(uint256 depositId, address user) external nonReentrant {
        uint256 chainId = block.chainid;
        bytes32 nullifier = keccak256(abi.encodePacked(chainId, depositId, user));
        require(!claimedSecure[nullifier], "Already claimed");
        claimedSecure[nullifier] = true;
        // release assets to `user`...
    }
}
