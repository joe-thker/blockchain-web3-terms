// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TipsetModule - Simulates Tipset Behavior and Security in Solidity

// ==============================
// 🧱 Basic Tipset Chain Simulation
// ==============================
contract TipsetChain {
    struct BlockData {
        address miner;
        bytes data;
    }

    struct Tipset {
        uint256 height;
        BlockData[] blocks;
        uint256 weight;
    }

    mapping(uint256 => Tipset) public tipsets; // height => tipset
    uint256 public currentHeight;

    event TipsetAdded(uint256 height, uint256 blockCount, uint256 weight);

    function addTipset(BlockData[] memory newBlocks, uint256 weight) public {
        currentHeight++;
        Tipset storage t = tipsets[currentHeight];
        t.height = currentHeight;
        t.weight = weight;

        for (uint256 i = 0; i < newBlocks.length; i++) {
            t.blocks.push(newBlocks[i]);
        }

        emit TipsetAdded(currentHeight, newBlocks.length, weight);
    }

    function getTipset(uint256 height) external view returns (BlockData[] memory) {
        return tipsets[height].blocks;
    }
}

// ==============================
// 🔓 Tipset Attacker: Inserts Duplicates or Junk Tips
// ==============================
interface ITipsetChain {
    function addTipset(TipsetChain.BlockData[] calldata, uint256) external;
}

contract TipsetAttack {
    function injectDuplicates(ITipsetChain chain) external {
        TipsetChain.BlockData ;
        dups[0] = TipsetChain.BlockData(msg.sender, "junk");
        dups[1] = TipsetChain.BlockData(msg.sender, "junk"); // duplicate
        chain.addTipset(dups, 1);
    }

    function spamTipset(ITipsetChain chain, uint256 count) external {
        TipsetChain.BlockData[] memory blocks = new TipsetChain.BlockData[](count);
        for (uint256 i = 0; i < count; i++) {
            blocks[i] = TipsetChain.BlockData(msg.sender, bytes(abi.encodePacked("spam-", i)));
        }
        chain.addTipset(blocks, 1);
    }
}

// ==============================
// 🔐 Safe Tipset Chain with Validation & Merge Rules
// ==============================
contract SafeTipsetChain {
    struct BlockData {
        address miner;
        bytes data;
    }

    struct Tipset {
        uint256 height;
        uint256 weight;
        bytes32 tipsetHash;
        mapping(bytes32 => bool) includedBlockHashes;
    }

    mapping(uint256 => Tipset) public tipsets;
    uint256 public currentHeight;

    event TipsetValidated(uint256 height, bytes32 tipsetHash, uint256 weight);

    function addValidatedTipset(BlockData[] calldata blocks, uint256 weight) external {
        require(blocks.length > 0 && blocks.length <= 5, "Invalid tipset size");

        currentHeight++;
        Tipset storage t = tipsets[currentHeight];
        t.height = currentHeight;
        t.weight = weight;

        bytes32 combined = keccak256(abi.encode(currentHeight, weight));
        for (uint256 i = 0; i < blocks.length; i++) {
            bytes32 bhash = keccak256(abi.encode(blocks[i].miner, blocks[i].data));
            require(!t.includedBlockHashes[bhash], "Duplicate block");
            t.includedBlockHashes[bhash] = true;
            combined = keccak256(abi.encodePacked(combined, bhash));
        }

        t.tipsetHash = combined;
        emit TipsetValidated(currentHeight, combined, weight);
    }

    function getTipsetHash(uint256 height) external view returns (bytes32) {
        return tipsets[height].tipsetHash;
    }
}
