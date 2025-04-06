contract MilestoneHiddenCap {
    address public owner;
    uint256[] public caps;
    uint256 public currentRound;
    uint256 public totalRaised;

    constructor(uint256[] memory _caps) {
        owner = msg.sender;
        caps = _caps;
    }

    receive() external payable {
        require(currentRound < caps.length, "No more rounds");
        require(totalRaised + msg.value <= caps[currentRound], "Round cap exceeded");

        totalRaised += msg.value;
    }

    function advanceRound() external {
        require(msg.sender == owner);
        require(currentRound < caps.length - 1, "Final round reached");
        currentRound++;
    }

    function withdraw() external {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    function currentCap() external view returns (uint256) {
        return caps[currentRound];
    }
}
