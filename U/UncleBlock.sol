// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title UncleBlockLogger - Logs block metadata (simulated uncle tracking)
contract UncleBlockLogger {
    struct BlockMeta {
        uint256 number;
        uint256 timestamp;
        bytes32 parentHash;
        bytes32 blockHash;
        uint256 gasUsed;
        uint256 baseFee;
    }

    mapping(uint256 => BlockMeta) public logs;
    event BlockLogged(uint256 blockNumber, bytes32 hash);

    function logCurrentBlock() external {
        uint256 number = block.number;
        logs[number] = BlockMeta({
            number: number,
            timestamp: block.timestamp,
            parentHash: blockhash(number - 1),
            blockHash: blockhash(number),
            gasUsed: block.gaslimit,
            baseFee: block.basefee
        });

        emit BlockLogged(number, blockhash(number));
    }

    function getBlockHash(uint256 number) external view returns (bytes32) {
        return blockhash(number);
    }
}
