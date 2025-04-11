contract OracleConsumer {
    address public oracle;
    uint256 public price;

    function update(uint256 _price) external {
        require(msg.sender == oracle, "Only oracle");
        price = _price;
    }
}
