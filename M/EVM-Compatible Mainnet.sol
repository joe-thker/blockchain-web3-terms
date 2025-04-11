contract EVMMainnetDemo {
    event TxExecuted(address indexed sender, uint256 value);

    function execute() external payable {
        emit TxExecuted(msg.sender, msg.value);
    }

    receive() external payable {}
}
