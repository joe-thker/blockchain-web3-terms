contract CollateralLong {
    mapping(address => uint256) public ethCollateral;
    mapping(address => uint256) public stableDebt;

    function deposit() external payable {
        ethCollateral[msg.sender] += msg.value;
    }

    function borrowStable() external {
        uint256 maxBorrow = ethCollateral[msg.sender] / 2;
        stableDebt[msg.sender] = maxBorrow;
        // In real use, mint stablecoin here
    }
}
