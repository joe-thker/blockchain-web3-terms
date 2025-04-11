contract TimedLowerLow {
    struct Low {
        uint256 price;
        uint256 timestamp;
    }

    Low public lastLow;

    function submitLow(uint256 newLow) external {
        require(block.timestamp > lastLow.timestamp + 1 days, "Daily only");
        require(newLow < lastLow.price || lastLow.price == 0, "Not a lower low");

        lastLow = Low(newLow, block.timestamp);
    }

    function getLast() external view returns (uint256, uint256) {
        return (lastLow.price, lastLow.timestamp);
    }
}
