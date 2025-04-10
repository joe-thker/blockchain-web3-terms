contract LiquidityPoolVault {
    mapping(address => uint256) public balances;
    uint256 public totalDeposits;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getShareValue() external view returns (uint256) {
        return totalDeposits == 0 ? 0 : address(this).balance / totalDeposits;
    }

    receive() external payable {}
}
