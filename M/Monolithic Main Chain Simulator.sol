contract MonolithicMainChain {
    event BlockProcessed(uint256 blockNumber, address proposer);

    function proposeBlock() external {
        emit BlockProcessed(block.number, msg.sender);
    }

    function executeTransaction(address to, uint256 amount) external {
        payable(to).transfer(amount);
    }

    receive() external payable {}
}
