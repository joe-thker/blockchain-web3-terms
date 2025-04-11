contract FakeUSDT {
    string public name = "Tether USD";
    string public symbol = "USDT";
    uint8 public decimals = 6;

    function transfer(address to, uint256 amount) external returns (bool) {
        // Looks like transfer worked
        return true;
    }

    function balanceOf(address user) external pure returns (uint256) {
        return 1_000_000 * 1e6;
    }
}
