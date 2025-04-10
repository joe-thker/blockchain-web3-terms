contract LeveragedLong {
    mapping(address => uint256) public balances;
    uint256 public leverage = 3;

    function mint() external payable {
        balances[msg.sender] += msg.value * leverage;
    }

    function redeem(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Too much");
        balances[msg.sender] -= amount;
        uint256 payout = amount / leverage;
        payable(msg.sender).transfer(payout);
    }

    receive() external payable {}
}
