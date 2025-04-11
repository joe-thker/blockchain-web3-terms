contract CallOptionLong {
    address public writer;
    uint256 public strike = 1 ether;
    uint256 public expiry;

    constructor(uint256 _expiry) {
        writer = msg.sender;
        expiry = _expiry;
    }

    function exercise() external payable {
        require(block.timestamp < expiry, "Expired");
        require(msg.value == strike, "Strike price required");
        // deliver 1 token, here we send back ETH to simulate profit
        payable(msg.sender).transfer(2 ether); // assume price doubled
    }

    receive() external payable {}
}
