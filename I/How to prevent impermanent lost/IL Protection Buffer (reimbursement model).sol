contract ILProtectedAMM {
    mapping(address => uint256) public depositValue;
    mapping(address => uint256) public withdrawalValue;

    uint256 public ilFund = 1000 ether; // Emergency compensation fund

    function deposit(address user, uint256 value) external {
        depositValue[user] = value;
    }

    function withdraw(address user, uint256 actualValue) external {
        withdrawalValue[user] = actualValue;
        if (actualValue < depositValue[user]) {
            uint256 loss = depositValue[user] - actualValue;
            require(ilFund >= loss, "Not enough IL fund");
            ilFund -= loss;
            payable(user).transfer(loss);
        }
    }
}
