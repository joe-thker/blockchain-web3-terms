contract CommonProfit {
    mapping(address => uint256) public shares;
    uint256 public totalContributions;

    receive() external payable {
        shares[msg.sender] += msg.value;
        totalContributions += msg.value;
    }

    function claimShare() external {
        uint256 payout = (address(this).balance * shares[msg.sender]) / totalContributions;
        payable(msg.sender).transfer(payout);
    }
}
