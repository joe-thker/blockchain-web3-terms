interface IERC20 {
    function transferFrom(address from, address to, uint256 amt) external returns (bool);
    function transfer(address to, uint256 amt) external returns (bool);
}

contract ERC20HostedWallet {
    address public host;
    IERC20 public token;
    mapping(address => uint256) public balances;

    constructor(address _token) {
        host = msg.sender;
        token = IERC20(_token);
    }

    function deposit(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[msg.sender] += amount;
    }

    function hostTransfer(address from, address to, uint256 amount) external {
        require(msg.sender == host, "Only host");
        require(balances[from] >= amount);
        balances[from] -= amount;
        balances[to] += amount;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0);
        balances[msg.sender] = 0;
        token.transfer(msg.sender, amount);
    }
}
