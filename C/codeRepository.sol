// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PublicCodeRepository {
    struct Commit {
        string commitHash;
        string message;
        uint256 timestamp;
        address author;
    }
    
    Commit[] public commits;
    
    event CommitAdded(uint256 indexed commitId, string commitHash, string message, uint256 timestamp, address author);
    
    /// @notice Adds a new commit to the public repository.
    /// @param commitHash The hash representing the commit.
    /// @param message A commit message describing the changes.
    function addCommit(string calldata commitHash, string calldata message) external {
        commits.push(Commit(commitHash, message, block.timestamp, msg.sender));
        emit CommitAdded(commits.length - 1, commitHash, message, block.timestamp, msg.sender);
    }
    
    /// @notice Retrieves a commit by its index.
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
