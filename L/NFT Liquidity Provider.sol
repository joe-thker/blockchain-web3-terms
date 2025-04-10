contract NFTLiquidityProvider {
    mapping(uint256 => address) public stakedNFTs;
    uint256 public totalStaked;

    function stakeNFT(uint256 tokenId) external {
        stakedNFTs[tokenId] = msg.sender;
        totalStaked++;
    }

    function unstakeNFT(uint256 tokenId) external {
        require(stakedNFTs[tokenId] == msg.sender, "Not your NFT");
        delete stakedNFTs[tokenId];
        totalStaked--;
    }
}
