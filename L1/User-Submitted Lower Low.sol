contract UserLowerLow {
    mapping(address => uint256[]) public lows;

    function submitLow(uint256 newLow) external {
        uint256 len = lows[msg.sender].length;
        if (len > 0) {
            require(newLow < lows[msg.sender][len - 1], "Not a lower low");
        }

        lows[msg.sender].push(newLow);
    }

    function getLastLow(address user) public view returns (uint256) {
        uint256 len = lows[user].length;
        return len > 0 ? lows[user][len - 1] : type(uint256).max;
    }
}
