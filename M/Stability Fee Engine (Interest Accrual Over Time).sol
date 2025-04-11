contract StabilityFee {
    mapping(address => uint256) public debt;
    mapping(address => uint256) public lastUpdated;
    uint256 public annualRate = 5; // 5% annual

    function accrueInterest(address user) public {
        uint256 elapsed = block.timestamp - lastUpdated[user];
        uint256 interest = (debt[user] * annualRate * elapsed) / (365 days * 100);
        debt[user] += interest;
        lastUpdated[user] = block.timestamp;
    }

    function borrow(uint256 amount) external {
        accrueInterest(msg.sender);
        debt[msg.sender] += amount;
        lastUpdated[msg.sender] = block.timestamp;
    }

    function repay(uint256 amount) external {
        accrueInterest(msg.sender);
        debt[msg.sender] -= amount;
    }
}
