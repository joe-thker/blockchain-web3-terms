contract PeerToPeerMarketplace {
    function listItem(string memory title, uint256 price) external {
        // No centralized control
    }

    function buyItem(address seller) external payable {
        payable(seller).transfer(msg.value);
    }
}
