// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleStorage is AccessControl {
    bytes32 public constant UPLOADER_ROLE = keccak256("UPLOADER_ROLE");

    struct File { string cid; uint256 size; uint256 ts; string tag; }

    mapping(address => File[]) private _files;

    event Stored(address indexed user, uint256 index, string cid);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPLOADER_ROLE, admin); // admin can upload by default
    }

    function grantUploader(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(UPLOADER_ROLE, account);
    }

    function revokeUploader(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(UPLOADER_ROLE, account);
    }

    function store(string calldata cid, uint256 size, string calldata tag)
        external onlyRole(UPLOADER_ROLE)
    {
        require(bytes(cid).length > 0, "empty cid");
        require(size > 0, "size zero");

        _files[msg.sender].push(File(cid, size, block.timestamp, tag));
        emit Stored(msg.sender, _files[msg.sender].length - 1, cid);
    }

    function fileCount(address u) external view returns (uint256) { return _files[u].length; }

    function getFile(address u, uint256 i)
        external view
        returns (string memory cid, uint256 size, uint256 ts, string memory tag)
    {
        require(i < _files[u].length, "index oob");
        File storage f = _files[u][i];
        return (f.cid, f.size, f.ts, f.tag);
    }
}
