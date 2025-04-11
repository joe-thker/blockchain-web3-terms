contract OracleLowerLow {
    address public oracle;
    uint256 public lastLow;

    event LowerLowDetected(uint256 newLow);

    constructor(address _oracle) {
        oracle = _oracle;
        lastLow = type(uint256).max;
    }

    function submitDailyLow(uint256 newLow) external {
        require(msg.sender == oracle, "Only oracle allowed");
        require(newLow < lastLow, "Not a lower low");

        lastLow = newLow;
        emit LowerLowDetected(newLow);
    }
}
