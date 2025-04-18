// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BasicOdysee
 * @notice Creators upload content metadata, viewers tip. No subscriptions.
 */
contract BasicOdysee is Ownable {
    constructor() Ownable(msg.sender) {}

    struct Content {
        address creator;
        string metadataURI;
        uint256 timestamp;
        uint256 totalTips;
    }

    mapping(uint256 => Content) public contents;
    uint256 public contentCount;

    event ContentUploaded(uint256 indexed contentId, address indexed creator, string metadataURI);
    event Tipped(uint256 indexed contentId, address indexed sender, uint256 amount);
    event TipsWithdrawn(uint256 indexed contentId, address indexed creator, uint256 amount);

    function uploadContent(string calldata metadataURI) external {
        require(bytes(metadataURI).length > 0, "URI required");
        uint256 id = contentCount++;
        contents[id] = Content(msg.sender, metadataURI, block.timestamp, 0);
        emit ContentUploaded(id, msg.sender, metadataURI);
    }

    function tip(uint256 contentId) external payable {
        Content storage c = contents[contentId];
        require(c.creator != address(0), "Not exist");
        require(msg.value > 0, "No tip");
        c.totalTips += msg.value;
        emit Tipped(contentId, msg.sender, msg.value);
    }

    function withdrawTips(uint256 contentId) external {
        Content storage c = contents[contentId];
        require(c.creator == msg.sender, "Not creator");
        uint256 amt = c.totalTips;
        require(amt > 0, "No tips");
        c.totalTips = 0;
        payable(msg.sender).transfer(amt);
        emit TipsWithdrawn(contentId, msg.sender, amt);
    }
}
