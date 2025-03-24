// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HybridCodeRepository {
    address public owner;
    
    struct Commit {
        string commitHash;
        string message;
        uint256 timestamp;
        address author;
    }
    
    Commit[] public commits;
    mapping(address => bool) public authorized;
    
    event CommitAdded(uint256 indexed commitId, string commitHash, string message, uint256 timestamp, address author);
    event AuthorizationGranted(address indexed addr);
    event AuthorizationRevoked(address indexed addr);
    
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // Owner is automatically authorized.
        authorized[msg.sender] = true;
    }
    
    /// @notice Grants commit access to an address.
    /// @param addr The address to authorize.
    function grantAuthorization(address addr) external onlyOwner {
        authorized[addr] = true;
        emit AuthorizationGranted(addr);
    }
    
    /// @notice Revokes commit access from an address.
    /// @param addr The address to revoke.
    function revokeAuthorization(address addr) external onlyOwner {
        authorized[addr] = false;
        emit AuthorizationRevoked(addr);
    }
    
    /// @notice Authorized users add a new commit.
    /// @param commitHash The commit hash.
    /// @param message The commit message.
    function addCommit(string calldata commitHash, string calldata message) external onlyAuthorized {
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
