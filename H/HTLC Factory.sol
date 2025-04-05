// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ETH HTLC
contract EthHTLC {
    address public sender;
    address public recipient;
    bytes32 public hashLock;
    uint256 public expiry;
    bool public claimed;

    constructor(
        address _recipient,
        bytes32 _hashLock,
        uint256 _duration
    ) payable {
        require(msg.value > 0, "No ETH sent");
        sender = msg.sender;
        recipient = _recipient;
        hashLock = _hashLock;
        expiry = block.timestamp + _duration;
    }

    function claim(bytes32 _secret) external {
        require(!claimed, "Already claimed");
        require(msg.sender == recipient, "Not recipient");
        require(keccak256(abi.encodePacked(_secret)) == hashLock, "Wrong secret");

        claimed = true;
        payable(msg.sender).transfer(address(this).balance);
    }

    function refund() external {
        require(block.timestamp >= expiry, "Too early");
        require(msg.sender == sender, "Not sender");
        require(!claimed, "Already claimed");

        payable(sender).transfer(address(this).balance);
    }
}

/// @title HTLC Factory for deploying ETH HTLCs
contract HTLCFactory {
    address[] public allHTLCs;

    event HTLCCreated(address indexed newHTLC);

    function createETHHTLC(
        address recipient,
        bytes32 hash,
        uint256 duration
    ) external payable {
        require(msg.value > 0, "Send ETH");

        // deploy HTLC and pass ETH to constructor
        EthHTLC htlc = (new EthHTLC){value: msg.value}(recipient, hash, duration);

        allHTLCs.push(address(htlc));
        emit HTLCCreated(address(htlc));
    }

    function getAllHTLCs() external view returns (address[] memory) {
        return allHTLCs;
    }
}
