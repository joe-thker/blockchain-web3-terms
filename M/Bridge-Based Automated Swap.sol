contract BridgeSwap {
    event LockAndBridge(address indexed user, uint256 amount, string destinationChain);

    mapping(address => uint256) public locked;

    function lockForBridge(string memory destinationChain) external payable {
        locked[msg.sender] += msg.value;
        emit LockAndBridge(msg.sender, msg.value, destinationChain);
    }

    function unlock(address user, uint256 amount) external {
        require(msg.sender == address(this), "Only bridge");
        locked[user] -= amount;
        payable(user).transfer(amount);
    }

    receive() external payable {}
}
