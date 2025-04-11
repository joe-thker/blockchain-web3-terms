contract WrapUnwrap {
    mapping(address => uint256) public wrappedETH;

    function wrap() external payable {
        wrappedETH[msg.sender] += msg.value;
    }

    function unwrap(uint256 amount) external {
        require(wrappedETH[msg.sender] >= amount, "Too much");
        wrappedETH[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}
