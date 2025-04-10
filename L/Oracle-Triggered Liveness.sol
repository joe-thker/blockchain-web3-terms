interface IOracle {
    function latestData() external view returns (uint256);
}

contract OracleLiveness {
    IOracle public oracle;
    uint256 public lastValue;

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    function updateFromOracle() external {
        uint256 value = oracle.latestData();
        require(value != lastValue, "No update");
        lastValue = value;
        // Oracle ensures liveness
    }
}
