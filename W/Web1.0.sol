// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title StaticWebRegistry - Web 1.0-style onchain public content store (read-only)
contract StaticWebRegistry {
    address public immutable publisher;
    string public contentTitle;
    string public contentIPFSHash;

    constructor(string memory _title, string memory _ipfsHash) {
        publisher = msg.sender;
        contentTitle = _title;
        contentIPFSHash = _ipfsHash;
    }

    function getContent() external view returns (string memory title, string memory ipfsHash) {
        return (contentTitle, contentIPFSHash);
    }

    function updateContent() external pure {
        revert("Web 1.0: static content cannot be updated");
    }
}
