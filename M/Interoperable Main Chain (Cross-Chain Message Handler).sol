contract InteroperableMainChain {
    event MessageReceived(uint256 fromChain, address from, string message);

    function receiveMessage(uint256 fromChainId, address sender, string calldata msgContent) external {
        emit MessageReceived(fromChainId, sender, msgContent);
    }
}
