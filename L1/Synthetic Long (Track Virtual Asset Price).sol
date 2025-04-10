contract SyntheticLong {
    mapping(address => uint256) public synth;
    uint256 public price = 2000 ether;

    function mint(uint256 amount) external payable {
        require(msg.value >= amount, "Need more ETH");
        synth[msg.sender] += amount;
    }

    function updatePrice(uint256 newPrice) external {
        price = newPrice;
    }

    function redeem() external {
        uint256 amt = synth[msg.sender];
        require(amt > 0, "None");
        synth[msg.sender] = 0;
        uint256 payout = (amt * price) / 1e18;
        payable(msg.sender).transfer(payout);
    }

    receive() external payable {}
}
