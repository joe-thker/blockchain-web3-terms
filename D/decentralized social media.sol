// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DecentralizedSocialMedia
/// @notice A decentralized social media platform allowing users to create, update, delete, and like posts.
/// The contract uses efficient data structures for minimal gas consumption and protects state-changing functions with ReentrancyGuard.
contract DecentralizedSocialMedia is ReentrancyGuard {
    /// @notice Structure to represent a post.
    struct Post {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        uint256 likeCount;
        bool active;
    }

    // Mapping from post ID to Post details.
    mapping(uint256 => Post) public posts;
    // Array of post IDs for easy enumeration of posts.
    uint256[] public postIds;
    // Counter for assigning the next post ID.
    uint256 public nextPostId;

    // Mapping to track which addresses have liked a particular post: postId => (voter => bool)
    mapping(uint256 => mapping(address => bool)) public likedBy;

    // --- Events ---
    event PostCreated(uint256 indexed postId, address indexed author, string content, uint256 timestamp);
    event PostUpdated(uint256 indexed postId, string newContent, uint256 timestamp);
    event PostDeleted(uint256 indexed postId, uint256 timestamp);
    event PostLiked(uint256 indexed postId, address indexed liker, uint256 likeCount);

    /// @notice Create a new post.
    /// @param content The content of the post.
    /// @return postId The unique identifier of the new post.
    function createPost(string calldata content) external nonReentrant returns (uint256 postId) {
        require(bytes(content).length > 0, "Content cannot be empty");

        postId = nextPostId++;
        posts[postId] = Post({
            id: postId,
            author: msg.sender,
            content: content,
            timestamp: block.timestamp,
            likeCount: 0,
            active: true
        });
        postIds.push(postId);

        emit PostCreated(postId, msg.sender, content, block.timestamp);
    }

    /// @notice Update an existing post's content.
    /// @param postId The ID of the post to update.
    /// @param newContent The new content for the post.
    function updatePost(uint256 postId, string calldata newContent) external nonReentrant {
        require(bytes(newContent).length > 0, "New content cannot be empty");
        Post storage post = posts[postId];
        require(post.active, "Post is not active");
        require(post.author == msg.sender, "Only the author can update the post");

        post.content = newContent;
        post.timestamp = block.timestamp; // Update timestamp on change

        emit PostUpdated(postId, newContent, block.timestamp);
    }

    /// @notice Delete a post (mark it as inactive).
    /// @param postId The ID of the post to delete.
    function deletePost(uint256 postId) external nonReentrant {
        Post storage post = posts[postId];
        require(post.active, "Post already inactive");
        require(post.author == msg.sender, "Only the author can delete the post");

        post.active = false;
        post.timestamp = block.timestamp; // Record deletion time

        emit PostDeleted(postId, block.timestamp);
    }

    /// @notice Like a post. Each address can like a specific post only once.
    /// @param postId The ID of the post to like.
    function likePost(uint256 postId) external nonReentrant {
        Post storage post = posts[postId];
        require(post.active, "Post is not active");
        require(!likedBy[postId][msg.sender], "Already liked this post");

        likedBy[postId][msg.sender] = true;
        post.likeCount++;

        emit PostLiked(postId, msg.sender, post.likeCount);
    }

    /// @notice Retrieves all post IDs.
    /// @return An array containing all post IDs.
    function getAllPostIds() external view returns (uint256[] memory) {
        return postIds;
    }
}
