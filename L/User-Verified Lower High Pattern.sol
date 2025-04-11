contract UserLowerHigh {
    mapping(address => uint256[]) public highs;

    function submitHigh(uint256 newHigh) external {
        uint256 len = highs[msg.sender].length;

        if (len >= 1) {
            require(newHigh < highs[msg.sender][len - 1], "Not a lower high");
        }

        highs[msg.sender].push(newHigh);
    }

    function getLatestHigh(address user) external view returns (uint256) {
        uint256 len = highs[user].length;
        return len > 0 ? highs[user][len - 1] : 0;
    }
}
