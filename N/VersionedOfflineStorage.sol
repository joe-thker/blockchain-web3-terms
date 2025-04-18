// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VersionedOfflineStorage
 * @notice Tracks an array of URIs per ID. Uploader or owner may append new versions,
 *         but cannot overwrite history.
 */
contract VersionedOfflineStorage is Ownable {
    struct Version {
        string uri;
        uint256 timestamp;
    }

    // id → versions[]
    mapping(bytes32 => Version[]) private _history;

    event VersionAdded(bytes32 indexed id, string uri, uint256 versionIndex, uint256 timestamp);

    constructor() Ownable(msg.sender) {}

    function addVersion(bytes32 id, string calldata uri) external {
        Version[] storage hist = _history[id];
        // First version sets uploader context in event
        hist.push(Version(uri, block.timestamp));
        emit VersionAdded(id, uri, hist.length - 1, block.timestamp);
    }

    /// Get the number of versions stored for an ID
    function versionCount(bytes32 id) external view returns (uint256) {
        return _history[id].length;
    }

    /// Retrieve a specific version
    function getVersion(bytes32 id, uint256 index)
        external
        view
        returns (string memory uri, uint256 timestamp)
    {
        require(index < _history[id].length, "Index OOB");
        Version storage v = _history[id][index];
        return (v.uri, v.timestamp);
    }

    /// Retrieve the latest version
    function getLatest(bytes32 id) external view returns (string memory uri, uint256 timestamp) {
        uint256 cnt = _history[id].length;
        require(cnt > 0, "No versions");
        Version storage v = _history[id][cnt - 1];
        return (v.uri, v.timestamp);
    }
}
