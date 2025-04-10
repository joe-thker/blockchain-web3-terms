contract NFTLiquidityPool {
    mapping(uint256 => address) public nftOwners;
    uint256 public ethReserve;

    function depositNFT(uint256 tokenId) external payable {
        require(msg.value > 0, "Must send ETH");
        nftOwners[tokenId] = msg.sender;
        ethReserve += msg.value;
    }

    function buyNFT(uint256 tokenId) external payable {
        require(msg.value >= ethReserve / 10, "Insufficient ETH");
        address owner = nftOwners[tokenId];
        delete nftOwners[tokenId];
        payable(owner).transfer(msg.value);
    }
}
