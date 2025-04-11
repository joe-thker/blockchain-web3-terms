contract LeveragedLongToken {
    mapping(address => uint256) public shares;
    uint256 public leverage = 3;
    uint256 public price = 1 ether;

    function mint() external payable {
        uint256 longValue = msg.value * leverage;
        shares[msg.sender] += longValue;
    }

    function redeem(uint256 amount) external {
        require(shares[msg.sender] >= amount);
        shares[msg.sender] -= amount;
        uint256 payout = amount / leverage;
        payable(msg.sender).transfer(payout);
    }

    receive() external payable {}
}
