contract SmartContractWallet {
    address public user;

    constructor(address _user) {
        user = _user;
    }

    receive() external payable {}

    function execute(address to, uint256 amount, bytes calldata data) external {
        require(msg.sender == user, "Not authorized");
        (bool ok, ) = to.call{value: amount}(data);
        require(ok, "Call failed");
    }
}
