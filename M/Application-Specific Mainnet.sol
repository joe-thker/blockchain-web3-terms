contract AppSpecificMainnet {
    mapping(address => uint256) public userBalances;

    function trade(address to, uint256 amount) external {
        userBalances[msg.sender] -= amount;
        userBalances[to] += amount;
    }

    function deposit() external payable {
        userBalances[msg.sender] += msg.value;
    }

    receive() external payable {}
}
