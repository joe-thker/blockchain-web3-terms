// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PrivateCodeRepository {
    address public owner;
    
    struct Commit {
        string commitHash;
        string message;
        uint256 timestamp;
        address author;
    }
    
    Commit[] public commits;
    
    event CommitAdded(uint256 indexed commitId, string commitHash, string message, uint256 timestamp, address author);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can add commits");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /// @notice Owner adds a new commit to the repository.
    /// @param commitHash The commit hash.
    /// @param message The commit message.
    function addCommit(string calldata commitHash, string calldata message) external onlyOwner {
        commits.push(Commit(commitHash, message, block.timestamp, msg.sender));
        emit CommitAdded(commits.length - 1, commitHash, message, block.timestamp, msg.sender);
    }
    
    /// @notice Retrieves a commit by index.
    /// @param index The index of the commit.
    /// @return The Commit struct.
    function getCommit(uint256 index) external view returns (Commit memory) {
        require(index < commits.length, "Index out of bounds");
        return commits[index];
    }
    
    /// @notice Returns the total number of commits.
    /// @return The commit count.
    function getCommitCount() external view returns (uint256) {
        return commits.length;
    }
}
