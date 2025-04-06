contract AirdropToken {
    mapping(address => bool) public claimed;

    function claim() external {
        require(!claimed[msg.sender], "Already claimed");
        claimed[msg.sender] = true;
        // Normally mint token here
    }
}
