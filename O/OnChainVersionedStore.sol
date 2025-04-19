// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OnChainVersionedStore
 * @notice Append‑only registry with full history.
 *         – Every update pushes a new version into an array per key.
 */
contract OnChainVersionedStore {
    struct Version {
        address editor;
        uint256 timestamp;
        string  value;
    }

    mapping(string => Version[]) private history;
    address public immutable owner;

    event VersionAdded(string indexed key, uint256 versionIndex, address editor, string value);

    constructor() { owner = msg.sender; }

    function addVersion(string calldata key, string calldata value) external {
        history[key].push(Version(msg.sender, block.timestamp, value));
        emit VersionAdded(key, history[key].length - 1, msg.sender, value);
    }

    function latest(string calldata key) external view returns (Version memory v) {
        uint256 n = history[key].length;
        require(n > 0, "no versions");
        v = history[key][n - 1];
    }

    function versionCount(string calldata key) external view returns (uint256) {
        return history[key].length;
    }

    function getVersion(string calldata key, uint256 idx) external view returns (Version memory) {
        require(idx < history[key].length, "oob");
        return history[key][idx];
    }
}
