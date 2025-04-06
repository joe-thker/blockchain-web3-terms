contract SessionHotWallet {
    address public user;
    uint256 public sessionExpires;

    constructor(address _user, uint256 _duration) payable {
        user = _user;
        sessionExpires = block.timestamp + _duration;
    }

    function withdraw() external {
        require(msg.sender == user, "Not user");
        require(block.timestamp <= sessionExpires, "Session expired");
        payable(user).transfer(address(this).balance);
    }
}
