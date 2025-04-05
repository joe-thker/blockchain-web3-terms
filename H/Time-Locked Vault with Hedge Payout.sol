contract TimeLockedHedge {
    address public depositor;
    uint256 public initialPrice;
    uint256 public duration;
    uint256 public hedgePayout;
    bool public withdrawn;
    uint256 public lockStart;

    constructor(uint256 _initialPrice, uint256 _duration) payable {
        require(msg.value > 0);
        depositor = msg.sender;
        initialPrice = _initialPrice;
        duration = _duration;
        hedgePayout = msg.value;
        lockStart = block.timestamp;
    }

    function withdraw(uint256 currentPrice) external {
        require(msg.sender == depositor);
        require(!withdrawn);
        require(block.timestamp >= lockStart + duration, "Not unlocked");

        withdrawn = true;

        if (currentPrice < initialPrice * 80 / 100) {
            // Price dropped more than 20% → hedge triggers
            payable(depositor).transfer(hedgePayout);
        }
    }
}
