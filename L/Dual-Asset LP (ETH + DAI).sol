interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract DualAssetLP {
    IERC20 public dai;
    mapping(address => uint256) public ethLiquidity;
    mapping(address => uint256) public daiLiquidity;

    constructor(address _dai) {
        dai = IERC20(_dai);
    }

    function provide(uint256 daiAmount) external payable {
        dai.transferFrom(msg.sender, address(this), daiAmount);
        ethLiquidity[msg.sender] += msg.value;
        daiLiquidity[msg.sender] += daiAmount;
    }

    function withdraw(uint256 ethAmount, uint256 daiAmount) external {
        require(ethLiquidity[msg.sender] >= ethAmount, "Insufficient ETH");
        require(daiLiquidity[msg.sender] >= daiAmount, "Insufficient DAI");

        ethLiquidity[msg.sender] -= ethAmount;
        daiLiquidity[msg.sender] -= daiAmount;

        dai.transfer(msg.sender, daiAmount);
        payable(msg.sender).transfer(ethAmount);
    }

    receive() external payable {}
}
