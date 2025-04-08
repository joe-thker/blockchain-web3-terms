// Smart Contract to Record JOMO Events
pragma solidity ^0.8.21;

contract JOMORegistry {
    event JOMORecorded(address indexed user, string reason, uint256 timestamp);

    function recordJOMO(string calldata reason) external {
        emit JOMORecorded(msg.sender, reason, block.timestamp);
    }
}
