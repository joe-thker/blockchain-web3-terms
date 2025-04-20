// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * BasicStorage
 * -------------------------------------------------
 * Anyone can register an IPFS / Arweave / Swarm CID
 * plus a size (bytes) and a textual tag.  No fees,
 * no owner controls.
 */
contract BasicStorage {
    struct File {
        string  cid;
        uint256 size;
        uint256 timestamp;
        string  tag;
    }

    mapping(address => File[]) private _files;

    event Stored(address indexed user, uint256 index, string cid);

    function store(string calldata cid, uint256 size, string calldata tag) external {
        require(bytes(cid).length > 0, "empty cid");
        require(size > 0, "size zero");

        _files[msg.sender].push(File({
            cid: cid,
            size: size,
            timestamp: block.timestamp,
            tag: tag
        }));

        emit Stored(msg.sender, _files[msg.sender].length - 1, cid);
    }

    function fileCount(address user) external view returns (uint256) {
        return _files[user].length;
    }

    function getFile(address user, uint256 idx)
        external view
        returns (string memory cid, uint256 size, uint256 ts, string memory tag)
    {
        require(idx < _files[user].length, "index oob");
        File storage f = _files[user][idx];
        return (f.cid, f.size, f.timestamp, f.tag);
    }
}
