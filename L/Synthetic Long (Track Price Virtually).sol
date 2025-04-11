contract SyntheticLong {
    mapping(address => uint256) public synthBalance;
    uint256 public syntheticPrice = 2000 ether;

    function mint(uint256 amount) external payable {
        require(msg.value >= amount, "Insufficient ETH");
        synthBalance[msg.sender] += amount;
    }

    function updateSyntheticPrice(uint256 newPrice) external {
        syntheticPrice = newPrice;
    }

    function redeem() external {
        uint256 amount = synthBalance[msg.sender];
        uint256 payout = (amount * syntheticPrice) / 1e18;
        synthBalance[msg.sender] = 0;
        payable(msg.sender).transfer(payout);
    }

    receive() external payable {}
}
