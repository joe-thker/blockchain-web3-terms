contract PriceBandHedge {
    address public user;
    uint256 public low;
    uint256 public high;
    uint256 public payout;
    uint256 public start;
    uint256 public duration;
    bool public claimed;

    constructor(address _user, uint256 _low, uint256 _high, uint256 _duration) payable {
        require(msg.value > 0, "Send hedge reserve");
        user = _user;
        low = _low;
        high = _high;
        payout = msg.value;
        duration = _duration;
        start = block.timestamp;
    }

    function claim(uint256 observedPrice) external {
        require(msg.sender == user, "Not user");
        require(block.timestamp >= start + duration, "Too early");
        require(!claimed, "Already claimed");

        if (observedPrice < low || observedPrice > high) {
            claimed = true;
            payable(user).transfer(payout);
        }
    }

    function refund() external {
        require(block.timestamp >= start + duration, "Not expired");
        require(!claimed);
        payable(msg.sender).transfer(address(this).balance);
    }
}
