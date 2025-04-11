contract MarginLong {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;

    function depositCollateral() external payable {
        collateral[msg.sender] += msg.value;
    }

    function borrowToLong() external {
        uint256 amount = collateral[msg.sender] * 2; // 2x leverage
        borrowed[msg.sender] = amount;
        // simulate long by emitting or tracking
    }

    function repay() external payable {
        borrowed[msg.sender] = 0;
    }

    receive() external payable {}
}
