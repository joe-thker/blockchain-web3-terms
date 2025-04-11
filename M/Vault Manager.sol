contract VaultManager {
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;
    uint256 public collateralRatio = 150; // 150%
    uint256 public daiPrice = 1e18; // 1 DAI = 1 USD
    uint256 public ethPrice = 2000e18; // 1 ETH = $2000

    function depositCollateral() external payable {
        collateral[msg.sender] += msg.value;
    }

    function mintDAI(uint256 amount) external {
        uint256 value = collateral[msg.sender] * ethPrice / 1e18;
        require(value * 100 / amount >= collateralRatio * daiPrice / 1e18, "Undercollateralized");
        debt[msg.sender] += amount;
        // mint DAI (simulate)
    }

    function repayDAI(uint256 amount) external {
        require(debt[msg.sender] >= amount, "Exceeds debt");
        debt[msg.sender] -= amount;
        // burn DAI (simulate)
    }
}
