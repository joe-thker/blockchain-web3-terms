// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Simulated Lightning-Style Payment Channel
contract LightningSim {
    address public sender;
    address public receiver;
    uint256 public deposit;
    uint256 public expiration;

    bool public isClosed;

    constructor(address _receiver, uint256 _duration) payable {
        sender = msg.sender;
        receiver = _receiver;
        deposit = msg.value;
        expiration = block.timestamp + _duration;
    }

    /// @notice Receiver closes the channel with a signed balance proof
    function close(uint256 amount, bytes calldata signature) external {
        require(!isClosed, "Channel closed");
        require(msg.sender == receiver, "Only receiver can close");

        bytes32 messageHash = keccak256(abi.encodePacked(address(this), amount));
        bytes32 ethSignedMessage = ECDSA.toEthSignedMessageHash(messageHash);
        require(ECDSA.recover(ethSignedMessage, signature) == sender, "Invalid signature");

        isClosed = true;
        payable(receiver).transfer(amount);
        payable(sender).transfer(deposit - amount);
    }

    /// @notice Failsafe: sender reclaims funds if channel not closed in time
    function timeout() external {
        require(block.timestamp > expiration, "Not expired");
        require(!isClosed, "Already closed");
        isClosed = true;
        payable(sender).transfer(deposit);
    }
}

library ECDSA {
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = split(sig);
        return ecrecover(hash, v, r, s);
    }

    function split(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
