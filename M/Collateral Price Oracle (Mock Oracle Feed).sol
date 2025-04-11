contract PriceOracle {
    address public admin;
    uint256 public ethPrice = 2000e18;

    constructor() {
        admin = msg.sender;
    }

    function updatePrice(uint256 newPrice) external {
        require(msg.sender == admin, "Only admin");
        ethPrice = newPrice;
    }

    function getPrice() external view returns (uint256) {
        return ethPrice;
    }
}
