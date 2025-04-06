contract RoleBasedHostedWallet {
    address public owner;
    mapping(address => bool) public managers;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender], "Not manager");
        _;
    }

    function addManager(address mgr) external onlyOwner {
        managers[mgr] = true;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    function managerTransfer(address from, address to, uint256 amt) external onlyManager {
        require(balances[from] >= amt);
        balances[from] -= amt;
        balances[to] += amt;
    }

    function withdraw() external {
        uint256 amt = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amt);
    }
}
