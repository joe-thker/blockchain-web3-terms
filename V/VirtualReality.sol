// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VRRealmAccess {
    address public immutable admin;
    uint256 public constant SESSION_DURATION = 1 hours;

    struct VRSession {
        uint256 expiresAt;
        bytes32 vrActionHash; // hashed offchain VR action commitment
    }

    mapping(address => VRSession) public sessions;
    mapping(address => bool) public verifiedAvatars;

    event SessionStarted(address indexed user, uint256 expiresAt);
    event ActionCommitted(address indexed user, bytes32 actionHash);
    event AvatarVerified(address indexed user);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function verifyAvatar(bytes32 digest, bytes memory sig) external {
        address recovered = recover(digest, sig);
        require(recovered == msg.sender, "Bad sig");
        verifiedAvatars[msg.sender] = true;
        emit AvatarVerified(msg.sender);
    }

    function startSession(bytes32 vrActionHash) external {
        require(verifiedAvatars[msg.sender], "Unverified avatar");
        sessions[msg.sender] = VRSession({
            expiresAt: block.timestamp + SESSION_DURATION,
            vrActionHash: vrActionHash
        });
        emit SessionStarted(msg.sender, block.timestamp + SESSION_DURATION);
        emit ActionCommitted(msg.sender, vrActionHash);
    }

    function isSessionActive(address user) external view returns (bool) {
        return block.timestamp < sessions[user].expiresAt;
    }

    function getActionHash(address user) external view returns (bytes32) {
        return sessions[user].vrActionHash;
    }

    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "Invalid sig");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(hash, v, r, s);
    }
}
