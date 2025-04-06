contract HostedVaultWithLimit {
    address public host;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastWithdrawTime;
    uint256 public dailyLimit = 1 ether;

    constructor() {
        host = msg.sender;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(amount <= dailyLimit, "Exceeds daily limit");
        require(block.timestamp >= lastWithdrawTime[msg.sender] + 1 days, "Too soon");
        require(balances[msg.sender] >= amount);

        balances[msg.sender] -= amount;
        lastWithdrawTime[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(amount);
    }
}
