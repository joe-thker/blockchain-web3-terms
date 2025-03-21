// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BlockweaveSimulator
/// @notice A simplified simulation of a blockweave where each new block references a randomly chosen previous block.
contract BlockweaveSimulator {
    // Define a block structure.
    struct Block {
        uint256 id;         // Unique block ID (sequential)
        uint256 timestamp;  // Block creation timestamp
        string data;        // Arbitrary data stored in the block
        bytes32 prevHash;   // Reference to a previous block's hash (simulated)
    }
    
    // Array of blocks representing the blockweave.
    Block[] public blocks;
    
    // Event emitted when a new block is created.
    event BlockCreated(uint256 indexed id, uint256 timestamp, string data, bytes32 prevHash);
    
    /// @notice Creates a new block in the blockweave.
    /// @param data The data to store in the block.
    function createBlock(string memory data) public {
        uint256 newId = blocks.length;
        uint256 currentTimestamp = block.timestamp;
        bytes32 previousHash;
        
        if (newId == 0) {
            // Genesis block: no previous block.
            previousHash = bytes32(0);
        } else {
            // Choose a random previous block index from 0 to newId-1.
            uint256 randomIndex = uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, newId))
            ) % newId;
            // For simulation, compute the previous hash as a hash of the chosen block's id and data.
            previousHash = keccak256(abi.encodePacked(blocks[randomIndex].id, blocks[randomIndex].data));
        }
        
        // Create and store the new block.
        Block memory newBlock = Block({
            id: newId,
            timestamp: currentTimestamp,
            data: data,
            prevHash: previousHash
        });
        blocks.push(newBlock);
        
        emit BlockCreated(newId, currentTimestamp, data, previousHash);
    }
    
    /// @notice Retrieves a block by its ID.
    /// @param id The ID of the block to retrieve.
    /// @return id_ The block's ID.
    /// @return timestamp The block's timestamp.
    /// @return data The data stored in the block.
    /// @return prevHash The previous block hash referenced.
    function getBlock(uint256 id) public view returns (
        uint256 id_,
        uint256 timestamp,
        string memory data,
        bytes32 prevHash
    ) {
        require(id < blocks.length, "Block does not exist");
        Block memory b = blocks[id];
        return (b.id, b.timestamp, b.data, b.prevHash);
    }
    
    /// @notice Returns the total number of blocks in the blockweave.
    /// @return The total block count.
    function totalBlocks() public view returns (uint256) {
        return blocks.length;
    }
}
