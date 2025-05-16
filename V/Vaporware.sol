// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VaporwareScanner - Detects inactive or fake contracts
contract VaporwareScanner {
    struct ContractInfo {
        bool exists;
        uint256 lastCodeSize;
        uint256 lastActiveBlock;
    }

    mapping(address => ContractInfo) public trackedContracts;
    uint256 public activityThreshold = 100; // blocks

    event ContractTracked(address indexed target, uint256 codeSize);
    event ContractFlagged(address indexed target, string reason);

    function trackContract(address target) external {
        require(!trackedContracts[target].exists, "Already tracked");

        uint256 codeSize;
        assembly {
            codeSize := extcodesize(target)
        }

        trackedContracts[target] = ContractInfo({
            exists: true,
            lastCodeSize: codeSize,
            lastActiveBlock: block.number
        });

        emit ContractTracked(target, codeSize);
    }

    function updateActivity(address target) external {
        require(trackedContracts[target].exists, "Not tracked");
        require(tx.origin == target || msg.sender == target, "Not contract source");
        trackedContracts[target].lastActiveBlock = block.number;
    }

    function checkVaporware(address target) external view returns (bool isVaporware, string memory reason) {
        ContractInfo memory info = trackedContracts[target];

        if (!info.exists) {
            return (true, "Not tracked");
        }

        uint256 codeSize;
        assembly {
            codeSize := extcodesize(target)
        }

        if (codeSize == 0) {
            return (true, "No contract code");
        }

        if (block.number - info.lastActiveBlock > activityThreshold) {
            return (true, "Inactive contract");
        }

        return (false, "Contract looks legit");
    }
}
