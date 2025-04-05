// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Hashed Time Lock Contract (HTLC) in Solidity
contract HashedTimeLock {
    address public sender;
    address public recipient;
    uint256 public amount;
    uint256 public expiration;
    bytes32 public hashLock;
    bool public withdrawn;
    bool public refunded;

    bytes32 private secret;

    event Locked(address indexed sender, uint256 amount, bytes32 hashLock, uint256 expiration);
    event Withdrawn(address indexed recipient, bytes32 secret);
    event Refunded(address indexed sender);

    constructor(
        address _recipient,
        bytes32 _hashLock,
        uint256 _duration
    ) payable {
        require(msg.value > 0, "Must send ETH");
        sender = msg.sender;
        recipient = _recipient;
        hashLock = _hashLock;
        expiration = block.timestamp + _duration;
        amount = msg.value;
        emit Locked(sender, amount, hashLock, expiration);
    }

    /// @notice Claim funds by revealing the pre-image (secret)
    function withdraw(bytes32 _secret) external {
        require(!withdrawn, "Already withdrawn");
        require(!refunded, "Already refunded");
        require(msg.sender == recipient, "Not recipient");
        require(keccak256(abi.encodePacked(_secret)) == hashLock, "Invalid secret");

        withdrawn = true;
        secret = _secret;

        payable(recipient).transfer(amount);
        emit Withdrawn(recipient, _secret);
    }

    /// @notice Refund if time expired
    function refund() external {
        require(block.timestamp >= expiration, "Too early");
        require(!withdrawn, "Already withdrawn");
        require(!refunded, "Already refunded");
        require(msg.sender == sender, "Only sender");

        refunded = true;
        payable(sender).transfer(amount);
        emit Refunded(sender);
    }

    /// @notice View secret (only available after withdrawal)
    function viewSecret() external view returns (bytes32) {
        require(withdrawn, "Not yet revealed");
        return secret;
    }
}
