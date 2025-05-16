// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ContentVault - Use Case: Pay-per-access for digital content using ETH
contract ContentVault {
    address public owner;
    uint256 public accessPrice;
    mapping(address => bool) public hasAccess;

    string private content;

    event AccessGranted(address indexed user);
    event PriceUpdated(uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _price, string memory _content) {
        owner = msg.sender;
        accessPrice = _price;
        content = _content;
    }

    function buyAccess() external payable {
        require(msg.value >= accessPrice, "Insufficient payment");
        hasAccess[msg.sender] = true;
        emit AccessGranted(msg.sender);
    }

    function viewContent() external view returns (string memory) {
        require(hasAccess[msg.sender], "No access");
        return content;
    }

    function updatePrice(uint256 _newPrice) external onlyOwner {
        accessPrice = _newPrice;
        emit PriceUpdated(_newPrice);
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
