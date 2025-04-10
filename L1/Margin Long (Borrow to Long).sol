contract MarginLong {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;

    uint256 public leverage = 2;

    function depositCollateral() external payable {
        collateral[msg.sender] += msg.value;
    }

    function borrow() external {
        uint256 amount = collateral[msg.sender] * (leverage - 1);
        borrowed[msg.sender] = amount;
        // simulate purchase of crypto with borrowed ETH
    }

    function repay() external payable {
        borrowed[msg.sender] = 0;
    }

    receive() external payable {}
}
