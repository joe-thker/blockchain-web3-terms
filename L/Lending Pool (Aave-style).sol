contract LendingPool {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
    }

    function borrow(uint256 amount) external {
        require(deposits[msg.sender] >= amount / 2, "Not enough collateral");
        borrows[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
    }

    function repay() external payable {
        borrows[msg.sender] -= msg.value;
    }
}
