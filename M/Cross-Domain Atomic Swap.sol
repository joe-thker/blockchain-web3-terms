contract HTLCMainnetSwap {
    struct Swap {
        address sender;
        uint256 amount;
        bytes32 hashlock;
        uint256 timeout;
        bool withdrawn;
    }

    mapping(bytes32 => Swap) public swaps;

    function initiateSwap(bytes32 hashlock, uint256 timeout) external payable {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, hashlock, block.timestamp));
        swaps[id] = Swap(msg.sender, msg.value, hashlock, block.timestamp + timeout, false);
    }

    function claim(bytes32 id, string memory secret) external {
        Swap storage s = swaps[id];
        require(!s.withdrawn, "Already claimed");
        require(s.hashlock == keccak256(abi.encodePacked(secret)), "Invalid secret");
        s.withdrawn = true;
        payable(msg.sender).transfer(s.amount);
    }

    function refund(bytes32 id) external {
        Swap storage s = swaps[id];
        require(block.timestamp > s.timeout, "Too early");
        require(!s.withdrawn, "Already withdrawn");
        require(s.sender == msg.sender, "Not sender");

        s.withdrawn = true;
        payable(msg.sender).transfer(s.amount);
    }

    receive() external payable {}
}
