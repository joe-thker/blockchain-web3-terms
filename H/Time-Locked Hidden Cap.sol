contract TimelockedCap {
    address public owner;
    uint256 public hiddenCap;
    uint256 public revealTime;

    uint256 public totalRaised;
    bool public capActive;

    constructor(uint256 _cap, uint256 _delay) {
        owner = msg.sender;
        hiddenCap = _cap;
        revealTime = block.timestamp + _delay;
    }

    receive() external payable {
        if (block.timestamp >= revealTime) capActive = true;
        if (capActive) {
            require(totalRaised + msg.value <= hiddenCap, "Cap exceeded");
        }
        totalRaised += msg.value;
    }

    function withdraw() external {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }
}
