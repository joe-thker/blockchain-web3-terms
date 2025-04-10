interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

contract POAPSwap {
    IERC721 public geoNFT;

    constructor(address _nft) {
        geoNFT = IERC721(_nft);
    }

    function geoSwap() external payable {
        require(geoNFT.balanceOf(msg.sender) > 0, "No geo-NFT found");
        // Swap logic here
    }
}
