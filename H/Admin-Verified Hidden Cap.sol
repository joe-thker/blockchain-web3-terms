contract AdminCapConfirm {
    address public owner;
    uint256 public cap;
    bool public capSet;
    uint256 public totalRaised;

    constructor() {
        owner = msg.sender;
    }

    function setCap(uint256 _cap) external {
        require(msg.sender == owner, "Not owner");
        require(!capSet, "Cap already set");
        cap = _cap;
        capSet = true;
    }

    receive() external payable {
        require(capSet, "Cap not activated yet");
        require(totalRaised + msg.value <= cap, "Cap exceeded");
        totalRaised += msg.value;
    }

    function withdraw() external {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }
}
