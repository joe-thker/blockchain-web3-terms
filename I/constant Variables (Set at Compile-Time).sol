contract ConstantMath {
    uint256 public constant YEAR_IN_SECONDS = 365 * 24 * 60 * 60;

    function getSecondsInYear() external pure returns (uint256) {
        return YEAR_IN_SECONDS;
    }
}
