// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
