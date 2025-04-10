contract SealedBidAuction {
    struct Bid {
        bytes32 commitment;
        uint256 value;
    }

    mapping(address => Bid) public bids;
    address public highestBidder;
    uint256 public highestBid;

    function commitBid(bytes32 commitment) external {
        bids[msg.sender] = Bid(commitment, 0);
    }

    function revealBid(uint256 bidAmount, string memory secret) external {
        bytes32 commitment = keccak256(abi.encodePacked(bidAmount, secret));
        require(commitment == bids[msg.sender].commitment, "Invalid reveal");

        bids[msg.sender].value = bidAmount;
        if (bidAmount > highestBid) {
            highestBid = bidAmount;
            highestBidder = msg.sender;
        }
    }
}
