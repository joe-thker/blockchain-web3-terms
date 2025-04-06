contract MobileHotWallet {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastDeposit;

    receive() external payable {
        balances[msg.sender] += msg.value;
        lastDeposit[msg.sender] = block.timestamp;
    }

    function withdraw() external {
        require(block.timestamp >= lastDeposit[msg.sender] + 10 seconds, "Quick lock-in");
        uint256 amt = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amt);
    }
}
