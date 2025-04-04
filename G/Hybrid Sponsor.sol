contract GSN_Hybrid {
    address public sponsor;
    mapping(address => uint256) public balance;

    constructor(address _sponsor) {
        sponsor = _sponsor;
    }

    function contribute() external payable {
        balance[msg.sender] += msg.value;
    }

    function partialSponsor(address user, uint256 topUp) external {
        require(msg.sender == sponsor, "Only sponsor");
        balance[user] += topUp;
    }

    function performAction() external {
        require(balance[msg.sender] >= 0.01 ether, "Insufficient");
        balance[msg.sender] -= 0.01 ether;
        // perform logic
    }
}
