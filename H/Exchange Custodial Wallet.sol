contract CustodialExchangeWallet {
    address public exchange;
    mapping(address => uint256) public balances;

    constructor() {
        exchange = msg.sender;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    function transferBetweenUsers(address from, address to, uint256 amount) external {
        require(msg.sender == exchange, "Only exchange");
        require(balances[from] >= amount, "Insufficient");
        balances[from] -= amount;
        balances[to] += amount;
    }

    function withdraw() external {
        uint256 amt = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amt);
    }
}
