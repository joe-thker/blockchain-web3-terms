contract CallOptionLong {
    address public owner;
    uint256 public strike = 1 ether;
    uint256 public expiry;

    constructor(uint256 _expiry) {
        owner = msg.sender;
        expiry = _expiry;
    }

    function exercise() external payable {
        require(block.timestamp < expiry, "Expired");
        require(msg.value == strike, "Need strike ETH");
        payable(msg.sender).transfer(2 ether); // simulate 2x return
    }

    receive() external payable {}
}
