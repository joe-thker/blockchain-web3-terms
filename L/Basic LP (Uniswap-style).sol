contract BasicLP {
    mapping(address => uint256) public shares;
    uint256 public totalShares;
    uint256 public reserveETH;

    function deposit() external payable {
        uint256 share = totalShares == 0 ? msg.value : (msg.value * totalShares) / reserveETH;
        shares[msg.sender] += share;
        totalShares += share;
        reserveETH += msg.value;
    }

    function withdraw(uint256 share) external {
        uint256 ethOut = (share * reserveETH) / totalShares;
        shares[msg.sender] -= share;
        totalShares -= share;
        reserveETH -= ethOut;
        payable(msg.sender).transfer(ethOut);
    }

    receive() external payable {}
}
