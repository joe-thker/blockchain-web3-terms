contract NodeSwap {
    mapping(address => bool) public whitelistedNode;
    mapping(address => bool) public swapped;

    function registerNode(address node) external {
        // Admin-approved node location
        whitelistedNode[node] = true;
    }

    function swapFromNode(address user) external {
        require(whitelistedNode[msg.sender], "Node not allowed");
        require(!swapped[user], "Already swapped");
        swapped[user] = true;
        // Transfer or mint tokens to `user`
    }
}
