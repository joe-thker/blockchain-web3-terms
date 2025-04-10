contract SpotLong {
    mapping(address => uint256) public balances;

    function buy() external payable {
        balances[msg.sender] += msg.value;
    }

    function sell() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount); // Assume price rose off-chain
    }

    receive() external payable {}
}
