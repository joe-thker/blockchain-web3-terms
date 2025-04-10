contract PerpLong {
    mapping(address => uint256) public position;
    uint256 public price = 1000 ether;

    function openLong(uint256 amountETH) external payable {
        require(msg.value == amountETH, "ETH mismatch");
        position[msg.sender] += (amountETH * 1e18) / price;
    }

    function updatePrice(uint256 newPrice) external {
        price = newPrice;
    }

    function closeLong() external {
        uint256 shares = position[msg.sender];
        uint256 currentValue = (shares * price) / 1e18;
        position[msg.sender] = 0;
        payable(msg.sender).transfer(currentValue); // gain/loss based on price
    }

    receive() external payable {}
}
