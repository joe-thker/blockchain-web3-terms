// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OdyseePlatform
 * @notice A simplified on‑chain version of a content platform like Odysee.
 *         Creators can upload content metadata, viewers can tip creators,
 *         and subscribe to creators for recurring access.
 */
contract OdyseePlatform is Ownable {
    // Pass the deployer’s address to Ownable’s constructor
    constructor() Ownable(msg.sender) {}

    struct Content {
        address creator;
        string metadataURI;       // e.g. IPFS hash or other off‑chain pointer
        uint256 timestamp;
        uint256 totalTips;        // accumulated tip amount
        uint256 subscriptionPrice;// price per subscription period (in wei)
    }

    // contentId → Content
    mapping(uint256 => Content) public contents;
    uint256 public contentCount;

    // contentId → subscriber → subscription expiry timestamp
    mapping(uint256 => mapping(address => uint256)) public subscriptions;

    event ContentUploaded(
        uint256 indexed contentId,
        address indexed creator,
        string metadataURI,
        uint256 timestamp
    );
    event Tipped(uint256 indexed contentId, address indexed sender, uint256 amount);
    event Subscribed(uint256 indexed contentId, address indexed subscriber, uint256 expiry);
    event TipsWithdrawn(uint256 indexed contentId, address indexed creator, uint256 amount);
    event SubscriptionPriceUpdated(uint256 indexed contentId, uint256 newPrice);

    /**
     * @notice Upload new content.
     * @param metadataURI The URI pointing to the content metadata (e.g. IPFS hash).
     * @param subscriptionPrice The price (in wei) for subscribing to this content.
     */
    function uploadContent(string calldata metadataURI, uint256 subscriptionPrice) external {
        require(bytes(metadataURI).length > 0, "Metadata URI required");
        uint256 contentId = contentCount++;
        contents[contentId] = Content({
            creator: msg.sender,
            metadataURI: metadataURI,
            timestamp: block.timestamp,
            totalTips: 0,
            subscriptionPrice: subscriptionPrice
        });
        emit ContentUploaded(contentId, msg.sender, metadataURI, block.timestamp);
    }

    /**
     * @notice Tip the creator of a piece of content.
     * @param contentId The ID of the content to tip.
     */
    function tipContent(uint256 contentId) external payable {
        Content storage c = contents[contentId];
        require(c.creator != address(0), "Content does not exist");
        require(msg.value > 0, "Tip must be > 0");
        c.totalTips += msg.value;
        emit Tipped(contentId, msg.sender, msg.value);
    }

    /**
     * @notice Subscribe to a content creator for one period.
     * @param contentId The ID of the content whose creator you wish to subscribe to.
     */
    function subscribe(uint256 contentId) external payable {
        Content storage c = contents[contentId];
        require(c.creator != address(0), "Content does not exist");
        require(c.subscriptionPrice > 0, "Subscriptions not enabled");
        require(msg.value == c.subscriptionPrice, "Incorrect subscription fee");

        uint256 currentExpiry = subscriptions[contentId][msg.sender];
        uint256 base = currentExpiry > block.timestamp ? currentExpiry : block.timestamp;
        uint256 newExpiry = base + 30 days;
        subscriptions[contentId][msg.sender] = newExpiry;

        emit Subscribed(contentId, msg.sender, newExpiry);
    }

    /**
     * @notice Withdraw accumulated tips for a piece of content.
     * @param contentId The ID of the content.
     */
    function withdrawTips(uint256 contentId) external {
        Content storage c = contents[contentId];
        require(c.creator == msg.sender, "Not content creator");
        uint256 amount = c.totalTips;
        require(amount > 0, "No tips to withdraw");
        c.totalTips = 0;
        payable(msg.sender).transfer(amount);
        emit TipsWithdrawn(contentId, msg.sender, amount);
    }

    /**
     * @notice Update the subscription price for your content.
     * @param contentId The ID of the content.
     * @param newPrice The new subscription price in wei.
     */
    function updateSubscriptionPrice(uint256 contentId, uint256 newPrice) external {
        Content storage c = contents[contentId];
        require(c.creator == msg.sender, "Not content creator");
        c.subscriptionPrice = newPrice;
        emit SubscriptionPriceUpdated(contentId, newPrice);
    }

    /**
     * @notice Check if a subscriber's subscription is active.
     * @param contentId The content ID.
     * @param subscriber The subscriber address.
     * @return True if subscription is not expired.
     */
    function isSubscribed(uint256 contentId, address subscriber) external view returns (bool) {
        return subscriptions[contentId][subscriber] >= block.timestamp;
    }

    /// @dev Fallback to accept direct ETH transfers (treated as tips to the platform owner)
    receive() external payable {}
}
