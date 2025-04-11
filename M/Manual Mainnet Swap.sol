contract ManualMainnetSwap {
    event BurnForSwap(address indexed user, uint256 amount, string targetChain);

    function burnToSwap(string calldata targetChain) external payable {
        emit BurnForSwap(msg.sender, msg.value, targetChain);
        // Backend listens → mints on target mainnet
    }

    receive() external payable {}
}
