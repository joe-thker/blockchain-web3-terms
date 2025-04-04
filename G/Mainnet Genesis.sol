pragma solidity ^0.8.20;

contract MainnetGenesis {
    address public genesisCreator;
    uint256 public genesisTime;
    bytes32 public genesisHash;

    constructor() {
        genesisCreator = msg.sender;
        genesisTime = block.timestamp;
        genesisHash = keccak256(abi.encodePacked(genesisCreator, genesisTime));
    }
}
