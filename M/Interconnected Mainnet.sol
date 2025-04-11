contract InterconnectedMainnet {
    event CrossChainTransfer(address indexed from, string destinationZone, uint256 amount);

    function sendToZone(string memory zone) external payable {
        emit CrossChainTransfer(msg.sender, zone, msg.value);
    }

    receive() external payable {}
}
