contract CollateralLong {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public debt;

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
    }

    function borrowStable() external {
        uint256 max = deposits[msg.sender] / 2;
        debt[msg.sender] = max;
        // simulate minting stablecoins
    }
}
