contract SpotLong {
    mapping(address => uint256) public balance;

    function buy() external payable {
        balance[msg.sender] += msg.value;
    }

    function sell() external {
        uint256 amt = balance[msg.sender];
        require(amt > 0, "Nothing to sell");
        balance[msg.sender] = 0;
        payable(msg.sender).transfer(amt); // Simplified: assume price increased
    }

    receive() external payable {}
}
