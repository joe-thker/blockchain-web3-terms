// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FanTokenNFT
 * @dev ERC721 NFT representing Fan Tokens. Fans can mint NFTs by paying a mint fee.
 */
contract FanTokenNFT is ERC721Enumerable, Ownable {
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 private _nextTokenId;

    event MintPriceUpdated(uint256 newMintPrice);

    /**
     * @dev Constructor sets the NFT name, symbol, mint price, and maximum supply.
     * @param _mintPrice Price to mint each NFT (in wei).
     * @param _maxSupply Maximum number of NFTs that can be minted.
     */
    constructor(uint256 _mintPrice, uint256 _maxSupply)
        ERC721("Fan Token NFT", "FANFT")
        Ownable(msg.sender)
    {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        _nextTokenId = 1;
    }

    /**
     * @dev Allows fans to mint an NFT by paying the mint price.
     */
    function mint() external payable {
        require(_nextTokenId <= maxSupply, "Max supply reached");
        require(msg.value >= mintPrice, "Insufficient ETH sent");
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @dev Allows the owner to update the mint price.
     */
    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
        emit MintPriceUpdated(newMintPrice);
    }

    /**
     * @dev Withdraws collected ETH to the owner's address.
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
