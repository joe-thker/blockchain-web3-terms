contract LendingLP {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public interestEarned;

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
    }

    function simulateInterest(uint256 amount) external {
        interestEarned[msg.sender] += amount;
    }

    function withdraw() external {
        uint256 total = deposits[msg.sender] + interestEarned[msg.sender];
        deposits[msg.sender] = 0;
        interestEarned[msg.sender] = 0;
        payable(msg.sender).transfer(total);
    }
}
