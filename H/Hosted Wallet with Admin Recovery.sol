contract HostedWalletWithRecovery {
    address public host;

    struct UserWallet {
        uint256 balance;
        address recovery;
    }

    mapping(address => UserWallet) public wallets;

    constructor() {
        host = msg.sender;
    }

    receive() external payable {
        wallets[msg.sender].balance += msg.value;
    }

    function setRecovery(address rec) external {
        wallets[msg.sender].recovery = rec;
    }

    function recover(address lostUser) external {
        require(msg.sender == wallets[lostUser].recovery, "Not recovery address");
        uint256 amt = wallets[lostUser].balance;
        wallets[lostUser].balance = 0;
        wallets[msg.sender].balance += amt;
    }

    function withdraw() external {
        uint256 amt = wallets[msg.sender].balance;
        require(amt > 0);
        wallets[msg.sender].balance = 0;
        payable(msg.sender).transfer(amt);
    }
}
