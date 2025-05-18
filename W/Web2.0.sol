// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Web2BoundGateway - Only allows actions initiated by signed Web2 + wallet binding
contract Web2BoundGateway {
    address public trustedBackend;

    mapping(bytes32 => bool) public usedNonces;

    event ActionExecuted(address indexed user, string action);

    constructor(address _trustedBackend) {
        trustedBackend = _trustedBackend;
    }

    function executeWeb2Action(
        address user,
        string calldata action,
        uint256 nonce,
        bytes calldata sig
    ) external {
        bytes32 digest = keccak256(abi.encodePacked(user, action, nonce, address(this)));
        require(!usedNonces[digest], "Already used");
        require(_recover(digest, sig) == trustedBackend, "Invalid backend sig");

        usedNonces[digest] = true;
        emit ActionExecuted(user, action);
        // Trigger onchain action linked to Web2 call
    }

    function _recover(bytes32 digest, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "Bad signature length");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(digest, v, r, s);
    }
}
