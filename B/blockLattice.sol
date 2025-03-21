// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockLatticeSimulator {
    // Enum representing the type of block.
    enum BlockType { SEND, RECEIVE }

    // Struct representing a block in an account's chain.
    struct AccountBlock {
        uint256 timestamp;     // The block's timestamp.
        uint256 amount;        // The amount associated with this block (e.g., sent or received).
        BlockType blockType;   // The type of the block (SEND or RECEIVE).
        bytes32 prevHash;      // The hash of the previous block in this account's chain.
        bytes32 blockHash;     // The computed hash of this block.
    }

    // Mapping from an account address to its array of blocks (its own chain).
    mapping(address => AccountBlock[]) public accountChains;

    // Event emitted when a new block is created.
    event BlockCreated(
        address indexed account,
        uint256 indexed index,
        bytes32 blockHash,
        BlockType blockType,
        uint256 amount
    );

    /// @notice Retrieves the last block hash of a given account's chain.
    /// @param account The account address.
    /// @return The hash of the last block, or 0 if no block exists.
    function getLastBlockHash(address account) public view returns (bytes32) {
        uint256 len = accountChains[account].length;
        if (len == 0) {
            return bytes32(0);
        } else {
            return accountChains[account][len - 1].blockHash;
        }
    }

    /// @notice Creates a new "send" block for the caller's account.
    /// @param amount The amount associated with the send block.
    /// @return index The index of the newly created block in the account's chain.
    function createSendBlock(uint256 amount) public returns (uint256 index) {
        return _createBlock(msg.sender, amount, BlockType.SEND);
    }

    /// @notice Creates a new "receive" block for the caller's account.
    /// @param amount The amount associated with the receive block.
    /// @return index The index of the newly created block in the account's chain.
    function createReceiveBlock(uint256 amount) public returns (uint256 index) {
        return _createBlock(msg.sender, amount, BlockType.RECEIVE);
    }

    /// @notice Internal function to create a new block in an account's chain.
    /// @param account The account for which to create the block.
    /// @param amount The amount associated with the block.
    /// @param blockType The type of block (SEND or RECEIVE).
    /// @return index The index of the newly created block.
    function _createBlock(
        address account,
        uint256 amount,
        BlockType blockType
    ) internal returns (uint256 index) {
        uint256 currentTimestamp = block.timestamp;
        bytes32 prevHash = getLastBlockHash(account);
        bytes32 newBlockHash = keccak256(
            abi.encodePacked(account, currentTimestamp, amount, blockType, prevHash)
        );
        AccountBlock memory newBlock = AccountBlock({
            timestamp: currentTimestamp,
            amount: amount,
            blockType: blockType,
            prevHash: prevHash,
            blockHash: newBlockHash
        });
        accountChains[account].push(newBlock);
        index = accountChains[account].length - 1;
        emit BlockCreated(account, index, newBlockHash, blockType, amount);
    }

    /// @notice Returns the entire block chain (array of blocks) for a given account.
    /// @param account The account address.
    /// @return The array of blocks representing the account's chain.
    function getChain(address account) public view returns (AccountBlock[] memory) {
        return accountChains[account];
    }
}
