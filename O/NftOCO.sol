// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NftOCO is ERC721, ERC721Votes {
    using SafeERC20 for IERC20;

    struct O {
        IERC20  asset;
        IERC20  quote;
        uint256 amt;
        uint256 tp;
        uint256 sl;
        address router;
        bool    executed;
        bool    cancelled;
    }

    uint256 public nextId = 1;
    mapping(uint256 => O) public data;

    event FilledTP(uint256 id);
    event FilledSL(uint256 id);
    event Cancelled(uint256 id);

    constructor() ERC721("OCO Position", "OCOP") EIP712("OCOP", "1") {}

    /* mint NFT + deposit asset */
    function mint(
        IERC20 asset,
        IERC20 quote,
        uint256 amt,
        uint256 tp,
        uint256 sl,
        address router
    ) external returns (uint256 id) {
        require(tp > sl, "tp <= sl");
        id = nextId++;
        _safeMint(msg.sender, id);
        asset.safeTransferFrom(msg.sender, address(this), amt);
        data[id] = O(asset, quote, amt, tp, sl, router, false, false);
    }

    /* anyone executes */
    function fillTP(uint256 id, uint256 price) external {
        O storage o = data[id];
        require(!_done(o), "inactive");
        require(price >= o.tp, "price < tp");
        o.executed = true;
        o.asset.safeTransfer(o.router, o.amt);
        emit FilledTP(id);
    }

    function fillSL(uint256 id, uint256 price) external {
        O storage o = data[id];
        require(!_done(o), "inactive");
        require(price <= o.sl, "price > sl");
        o.executed = true;
        o.asset.safeTransfer(o.router, o.amt);
        emit FilledSL(id);
    }

    /* holder can cancel */
    function cancel(uint256 id) external {
        require(ownerOf(id) == msg.sender, "not holder");
        O storage o = data[id];
        require(!_done(o), "inactive");
        o.cancelled = true;
        o.asset.safeTransfer(msg.sender, o.amt);
        emit Cancelled(id);
    }

    /* internal */
    function _done(O storage o) private view returns (bool) {
        return o.executed || o.cancelled;
    }

    /* single transfer hook (OZ v5.x) */
    function _update(address from, address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Votes)
        returns (address)
    { return super._update(from, to, tokenId, auth); }
}
