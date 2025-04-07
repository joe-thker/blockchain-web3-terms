// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FiatOnRampERC721
 * @dev ERC721 token that acts as a fiat on-ramp.
 * When a user deposits ETH, a unique NFT is minted as a voucher representing the deposit.
 */
contract FiatOnRampERC721 is ERC721Enumerable, Ownable {
    // Conversion rate is optional for NFTs; here we simply record the deposit amount.
    mapping(uint256 => uint256) public depositAmount;
    uint256 private _nextTokenId;

    event Deposited(address indexed user, uint256 ethAmount, uint256 tokenId);
    event RateUpdated(uint256 newRate);

    /**
     * @dev Constructor sets the NFT name and symbol.
     */
    constructor() ERC721("Fiat On-Ramp NFT", "FORNFT") Ownable(msg.sender) {
        _nextTokenId = 1;
    }

    /**
     * @dev Deposits ETH and mints an NFT voucher to the sender.
     */
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        depositAmount[tokenId] = msg.value;
        _safeMint(msg.sender, tokenId);
        emit Deposited(msg.sender, msg.value, tokenId);
    }

    // (Optional) If you want a conversion rate for NFTs, you can add a setter and store it.
}
