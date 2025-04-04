contract GSN_Paymaster {
    mapping(address => bool) public eligible;
    mapping(address => uint256) public gasPaid;

    function register(address user) external {
        eligible[user] = true;
    }

    function sponsorGas(address user, uint256 gasAmount) external {
        require(eligible[user], "Not eligible");
        gasPaid[user] += gasAmount;
        // Logic to reimburse gas (mock only)
    }
}
