// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VitalikGuardian {
    address public immutable vitalikAddress;
    mapping(bytes32 => bool) public usedDigests;

    event EmergencyTriggered(string message, address triggeredBy);
    event VerifiedAction(address indexed by, bytes32 digest);

    constructor(address _vitalik) {
        vitalikAddress = _vitalik;
    }

    modifier onlyVitalik(bytes32 digest, bytes calldata sig) {
        require(!usedDigests[digest], "Replay blocked");
        address signer = recover(digest, sig);
        require(signer == vitalikAddress, "Invalid signature");
        usedDigests[digest] = true;
        emit VerifiedAction(signer, digest);
        _;
    }

    function emergencyPause(string calldata message, bytes32 digest, bytes calldata sig)
        external onlyVitalik(digest, sig)
    {
        emit EmergencyTriggered(message, msg.sender);
        // Pause system, revoke access, etc.
    }

    function recover(bytes32 digest, bytes memory sig) public pure returns (address) {
        require(sig.length == 65, "Bad sig length");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(digest, v, r, s);
    }
}
