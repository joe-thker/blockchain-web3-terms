// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SubscriptionOdysee
 * @notice Adds per‑content subscriptions (30 days), plus tipping.
 */
contract SubscriptionOdysee is Ownable {
    constructor() Ownable(msg.sender) {}

    struct Content {
        address creator;
        string metadataURI;
        uint256 timestamp;
        uint256 totalTips;
        uint256 subPrice; // wei per period
    }

    mapping(uint256 => Content) public contents;
    uint256 public contentCount;
    mapping(uint256 => mapping(address => uint256)) public expiry; // contentId→user→expiry

    event ContentUploaded(uint256 indexed id, address indexed creator, string uri, uint256 subPrice);
    event Tipped(uint256 indexed id, address indexed who, uint256 amt);
    event Subscribed(uint256 indexed id, address indexed who, uint256 expiryTs);
    event TipsWithdrawn(uint256 indexed id, address indexed creator, uint256 amt);
    event SubscriptionPriceUpdated(uint256 indexed id, uint256 newPrice);

    function uploadContent(string calldata uri, uint256 subPrice) external {
        require(bytes(uri).length > 0, "URI req");
        uint256 id = contentCount++;
        contents[id] = Content(msg.sender, uri, block.timestamp, 0, subPrice);
        emit ContentUploaded(id, msg.sender, uri, subPrice);
    }

    function tip(uint256 id) external payable {
        Content storage c = contents[id];
        require(c.creator != address(0), "Not exist");
        require(msg.value > 0, "No tip");
        c.totalTips += msg.value;
        emit Tipped(id, msg.sender, msg.value);
    }

    function subscribe(uint256 id) external payable {
        Content storage c = contents[id];
        require(c.creator != address(0), "Not exist");
        require(c.subPrice > 0, "No subscription");
        require(msg.value == c.subPrice, "Bad fee");

        uint256 base = expiry[id][msg.sender] > block.timestamp
            ? expiry[id][msg.sender]
            : block.timestamp;
        uint256 e = base + 30 days;
        expiry[id][msg.sender] = e;
        emit Subscribed(id, msg.sender, e);
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

    function updateSubscriptionPrice(uint256 id, uint256 newPrice) external {
        Content storage c = contents[id];
        require(c.creator == msg.sender, "Not creator");
        c.subPrice = newPrice;
        emit SubscriptionPriceUpdated(id, newPrice);
    }

    function isSubscribed(uint256 id, address user) external view returns (bool) {
        return expiry[id][user] >= block.timestamp;
    }
}
