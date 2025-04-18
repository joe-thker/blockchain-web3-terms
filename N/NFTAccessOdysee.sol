// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title NFTAccessOdysee
 * @notice On subscribe, mints an NFT as an access pass. Holders can view content.
 */
contract NFTAccessOdysee is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Content {
        address creator;
        string metadataURI;
        uint256 timestamp;
        uint256 totalTips;
        uint256 accessPrice; // wei per pass
    }

    mapping(uint256 => Content) public contents;
    uint256 public contentCount;
    mapping(uint256 => uint256) private _tokenToContent; // tokenId → contentId

    event ContentUploaded(uint256 indexed id, address indexed creator, string uri, uint256 accessPrice);
    event Tipped(uint256 indexed id, address indexed who, uint256 amt);
    event AccessPassMinted(uint256 indexed id, address indexed holder, uint256 tokenId);
    event TipsWithdrawn(uint256 indexed id, address indexed creator, uint256 amt);
    event AccessPriceUpdated(uint256 indexed id, uint256 newPrice);

    constructor() ERC721("OdyseeAccess", "OAC") Ownable(msg.sender) {}

    function uploadContent(string calldata uri, uint256 price) external {
        require(bytes(uri).length > 0, "URI req");
        uint256 id = contentCount++;
        contents[id] = Content(msg.sender, uri, block.timestamp, 0, price);
        emit ContentUploaded(id, msg.sender, uri, price);
    }

    function tip(uint256 id) external payable {
        Content storage c = contents[id];
        require(c.creator != address(0), "Not exist");
        require(msg.value > 0, "No tip");
        c.totalTips += msg.value;
        emit Tipped(id, msg.sender, msg.value);
    }

    function buyAccess(uint256 id) external payable {
        Content storage c = contents[id];
        require(c.creator != address(0), "Not exist");
        require(c.accessPrice > 0, "No access");
        require(msg.value == c.accessPrice, "Bad fee");
        // mint NFT access
        uint256 tk = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tk);
        _tokenToContent[tk] = id;
        emit AccessPassMinted(id, msg.sender, tk);
    }

    function withdrawTips(uint256 id) external {
        Content storage c = contents[id];
        require(c.creator == msg.sender, "Not creator");
        uint256 amt = c.totalTips;
        require(amt > 0, "No tips");
        c.totalTips = 0;
        payable(msg.sender).transfer(amt);
        emit TipsWithdrawn(id, msg.sender, amt);
    }

    function updateAccessPrice(uint256 id, uint256 newPrice) external {
        Content storage c = contents[id];
        require(c.creator == msg.sender, "Not creator");
        c.accessPrice = newPrice;
        emit AccessPriceUpdated(id, newPrice);
    }

    /// @notice Check if `user` holds an access NFT for content `id`.
    function hasAccess(uint256 id, address user) external view returns (bool) {
        uint256 total = balanceOf(user);
        for (uint256 i = 0; i < total; i++) {
            uint256 tk = tokenOfOwnerByIndex(user, i);
            if (_tokenToContent[tk] == id) return true;
        }
        return false;
    }

    // override required by Solidity

    function supportsInterface(bytes4 iid)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(iid);
    }
}
