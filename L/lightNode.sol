// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Light Client Header Verifier
/// @notice Stores and verifies minimal block headers like a light node
contract LightClient {
    struct Header {
        bytes32 blockHash;
        uint256 blockNumber;
        bytes32 parentHash;
    }

    mapping(uint256 => Header) public headers;
    uint256 public latestBlock;

    event HeaderSubmitted(uint256 blockNumber, bytes32 blockHash);

    function submitHeader(
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 parentHash
    ) external {
        require(headers[blockNumber].blockHash == bytes32(0), "Already submitted");

        if (blockNumber > 0) {
            require(headers[blockNumber - 1].blockHash == parentHash, "Invalid parent");
        }

        headers[blockNumber] = Header(blockHash, blockNumber, parentHash);
        latestBlock = blockNumber;

        emit HeaderSubmitted(blockNumber, blockHash);
    }

    function getLatestHeader() external view returns (Header memory) {
        return headers[latestBlock];
    }
}
