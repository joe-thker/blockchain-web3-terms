// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockProducerSimulator
/// @notice This contract simulates a simple producer system where addresses can register as producers
/// and then produce blocks (record block production events).
contract BlockProducerSimulator {
    address public owner;
    
    // Mapping to track registered producers.
    mapping(address => bool) public registeredProducers;
    
    // Array to store the list of produced blocks (for simulation purposes).
    struct ProducedBlock {
        address producer;
        uint256 blockNumber;
        uint256 timestamp;
    }
    
    ProducedBlock[] public producedBlocks;
    
    // Events for registration and block production.
    event ProducerRegistered(address indexed producer);
    event BlockProduced(address indexed producer, uint256 blockNumber, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Allows an address to register as a producer.
    function registerProducer() public {
        require(!registeredProducers[msg.sender], "Already registered");
        registeredProducers[msg.sender] = true;
        emit ProducerRegistered(msg.sender);
    }

    /// @notice Allows a registered producer to simulate block production.
    /// This function logs an event and stores block production details.
    function produceBlock() public {
        require(registeredProducers[msg.sender], "Not a registered producer");
        ProducedBlock memory newBlock = ProducedBlock({
            producer: msg.sender,
            blockNumber: block.number,
            timestamp: block.timestamp
        });
        producedBlocks.push(newBlock);
        emit BlockProduced(msg.sender, block.number, block.timestamp);
    }

    /// @notice Returns the total number of produced blocks in this simulation.
    /// @return The number of produced blocks.
    function getProducedBlockCount() public view returns (uint256) {
        return producedBlocks.length;
    }
}
