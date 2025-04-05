contract BiDirectionalHTLC {
    address public partyA;
    address public partyB;
    bytes32 public hashLock;
    uint256 public expiry;
    bool public isClaimed;

    constructor(address _partyB, bytes32 _hashLock, uint256 _duration) payable {
        require(msg.value > 0);
        partyA = msg.sender;
        partyB = _partyB;
        hashLock = _hashLock;
        expiry = block.timestamp + _duration;
    }

    function claim(bytes32 secret) external {
        require(!isClaimed, "Already claimed");
        require(msg.sender == partyB || msg.sender == partyA, "Unauthorized");
        require(keccak256(abi.encodePacked(secret)) == hashLock, "Invalid secret");

        isClaimed = true;
        payable(msg.sender).transfer(address(this).balance);
    }

    function refund() external {
        require(block.timestamp >= expiry, "Too early");
        require(!isClaimed, "Already claimed");
        require(msg.sender == partyA || msg.sender == partyB, "Unauthorized");

        payable(msg.sender).transfer(address(this).balance);
    }
}
