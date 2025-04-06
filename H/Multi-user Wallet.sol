contract MultiUserHostedWallet {
    address public host;
    mapping(address => uint256) public balances;

    constructor() {
        host = msg.sender;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    function hostTransfer(address from, address to, uint256 amount) external {
        require(msg.sender == host, "Only host");
        require(balances[from] >= amount, "Insufficient");
        balances[from] -= amount;
        balances[to] += amount;
    }

    function withdraw() external {
        uint256 amt = balances[msg.sender];
        require(amt > 0, "No balance");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amt);
    }
}
