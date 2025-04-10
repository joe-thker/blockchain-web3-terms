contract BondingCurveMarket {
    uint256 public totalSupply;
    uint256 public constant priceMultiplier = 0.01 ether;

    mapping(address => uint256) public balances;

    function buy() external payable {
        uint256 tokensToMint = msg.value / (priceMultiplier * (totalSupply + 1));
        balances[msg.sender] += tokensToMint;
        totalSupply += tokensToMint;
    }

    function sell(uint256 amount) external {
        require(balances[msg.sender] >= amount);
        uint256 ethToReturn = amount * priceMultiplier * (totalSupply - amount + 1);
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        payable(msg.sender).transfer(ethToReturn);
    }
}
