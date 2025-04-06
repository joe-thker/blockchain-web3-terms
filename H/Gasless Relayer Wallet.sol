contract GaslessWallet {
    address public user;
    address public relayer;

    constructor(address _user, address _relayer) {
        user = _user;
        relayer = _relayer;
    }

    function relayedTransfer(address payable to, uint256 amount) external {
        require(msg.sender == relayer, "Not relayer");
        to.transfer(amount);
    }

    receive() external payable {}
}
