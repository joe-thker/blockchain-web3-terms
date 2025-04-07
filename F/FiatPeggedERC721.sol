// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FiatPeggedNFT
 * @dev ERC721 token representing a fiat-backed asset claim.
 * Each NFT serves as a deposit certificate for off-chain fiat reserves.
 */
contract FiatPeggedNFT is ERC721Enumerable, Ownable {
    uint256 private _nextTokenId;

    // Mapping from token ID to the fiat deposit amount (in smallest unit, if desired).
    mapping(uint256 => uint256) public depositAmount;

    event NFTMinted(address indexed to, uint256 tokenId, uint256 amount);

    /**
     * @dev Constructor sets the token name and symbol and assigns the deployer as owner.
     */
    constructor() ERC721("Fiat Pegged NFT", "FPNFT") Ownable(msg.sender) {
        _nextTokenId = 1;
    }
    
    /**
     * @dev Mints a new NFT to a specified address, recording the deposit amount.
     * Can only be called by the owner.
     * @param to The address that will receive the NFT.
     * @param amount The fiat deposit amount corresponding to this NFT.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
        depositAmount[tokenId] = amount;
        emit NFTMinted(to, tokenId, amount);
    }
}
