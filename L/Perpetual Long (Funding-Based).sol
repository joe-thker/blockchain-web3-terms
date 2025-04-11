contract PerpetualLong {
    mapping(address => uint256) public position;
    uint256 public price = 1000 ether;

    function open(uint256 ethAmount) external payable {
        require(msg.value == ethAmount, "Mismatch");
        position[msg.sender] += (ethAmount * 1e18) / price;
    }

    function updatePrice(uint256 newPrice) external {
        price = newPrice;
    }

    function close() external {
        uint256 size = position[msg.sender];
        require(size > 0, "No position");
        uint256 currentValue = (size * price) / 1e18;
        position[msg.sender] = 0;
        payable(msg.sender).transfer(currentValue);
    }

    receive() external payable {}
}
