contract TimedLowerHigh {
    struct HighPoint {
        uint256 price;
        uint256 timestamp;
    }

    HighPoint public lastHigh;

    function submitTimedHigh(uint256 price) external {
        require(block.timestamp > lastHigh.timestamp + 1 hours, "Too soon");

        require(price < lastHigh.price || lastHigh.price == 0, "Not a lower high");

        lastHigh = HighPoint(price, block.timestamp);
    }

    function getLastHigh() external view returns (uint256 price, uint256 time) {
        return (lastHigh.price, lastHigh.timestamp);
    }
}
