contract Auction {
    uint256 public highestBid;
    address public winner;

    function bid() external payable {
        require(msg.value > highestBid, "Too low");
        highestBid = msg.value;
        winner = msg.sender;
    }
}
