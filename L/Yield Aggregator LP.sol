contract YieldAggregatorLP {
    mapping(address => uint256) public deposited;
    mapping(address => uint256) public autoYield;

    function deposit() external payable {
        deposited[msg.sender] += msg.value;
    }

    function simulateEarnings() external {
        autoYield[msg.sender] += deposited[msg.sender] / 10; // 10% gain
    }

    function withdraw() external {
        uint256 total = deposited[msg.sender] + autoYield[msg.sender];
        deposited[msg.sender] = 0;
        autoYield[msg.sender] = 0;
        payable(msg.sender).transfer(total);
    }

    receive() external payable {}
}
