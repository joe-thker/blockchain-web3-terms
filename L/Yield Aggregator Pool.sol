contract YieldAggregator {
    mapping(address => uint256) public balance;
    uint256 public totalYield;

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    function simulateYield(uint256 amount) external {
        totalYield += amount;
    }

    function claimYield() external {
        uint256 share = (balance[msg.sender] * totalYield) / address(this).balance;
        payable(msg.sender).transfer(share);
        totalYield -= share;
    }

    receive() external payable {}
}
