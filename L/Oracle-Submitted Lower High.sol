contract OracleLowerHigh {
    address public oracle;
    uint256 public lastHigh;

    event LowerHighConfirmed(uint256 newHigh);

    constructor(address _oracle) {
        oracle = _oracle;
        lastHigh = type(uint256).max;
    }

    function submitHigh(uint256 newHigh) external {
        require(msg.sender == oracle, "Only oracle");
        require(newHigh < lastHigh, "Not a lower high");

        lastHigh = newHigh;
        emit LowerHighConfirmed(newHigh);
    }
}
