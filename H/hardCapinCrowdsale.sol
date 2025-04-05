contract HardCappedSale {
    address public owner;
    uint256 public hardCap = 100 ether;
    uint256 public totalRaised;

    mapping(address => uint256) public contributions;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        require(totalRaised + msg.value <= hardCap, "Hard cap exceeded");
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
    }

    function withdraw() external {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }
}
