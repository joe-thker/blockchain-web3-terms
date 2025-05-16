// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VerificationCodeGate - One-time verifiable code authentication
contract VerificationCodeGate {
    address public immutable admin;
    mapping(bytes32 => bool) public usedCodes;
    mapping(address => uint256) public nonces;

    event CodeVerified(address indexed user, bytes32 codeHash, uint256 nonce);

    constructor() {
        admin = msg.sender;
    }

    /// @notice Submit verification code for access (code = hashed offline)
    function submitCode(
        bytes32 codeHash,
        uint256 expiry,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(block.timestamp <= expiry, "Code expired");
        require(nonces[msg.sender] == nonce, "Invalid nonce");
        require(!usedCodes[codeHash], "Code reused");

        bytes32 digest = keccak256(
            abi.encodePacked(codeHash, msg.sender, expiry, nonce, address(this))
        );

        address signer = recover(digest, signature);
        require(signer == admin, "Unauthorized signer");

        usedCodes[codeHash] = true;
        nonces[msg.sender]++;
        emit CodeVerified(msg.sender, codeHash, nonce);
    }

    function recover(bytes32 digest, bytes memory sig) public pure returns (address) {
        require(sig.length == 65, "Bad signature");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(digest, v, r, s);
    }

    function getDigest(
        bytes32 codeHash,
        uint256 expiry,
        uint256 nonce,
        address sender
    ) external view returns (bytes32) {
        return keccak256(abi.encodePacked(codeHash, sender, expiry, nonce, address(this)));
    }
}
