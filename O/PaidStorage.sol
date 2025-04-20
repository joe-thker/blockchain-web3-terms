// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PaidStorage is Ownable {
    struct File { string cid; uint256 size; uint256 ts; string tag; }

    mapping(address => File[]) private _files;
    uint256 public pricePerByte = 1e9; // 1 gwei / byte (example)

    event Stored(address indexed user, uint256 index, string cid);
    event PriceSet(uint256 price);
    event Withdraw(address to, uint256 amount);

    constructor() Ownable(msg.sender) {}

    function store(string calldata cid, uint256 size, string calldata tag) external payable {
        require(bytes(cid).length > 0, "empty cid");
        require(size > 0, "size zero");

        uint256 cost = size * pricePerByte;
        require(msg.value >= cost, "fee too low");

        _files[msg.sender].push(File(cid, size, block.timestamp, tag));
        emit Stored(msg.sender, _files[msg.sender].length - 1, cid);

        // refund excess
        if (msg.value > cost) payable(msg.sender).transfer(msg.value - cost);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        pricePerByte = newPrice;
        emit PriceSet(newPrice);
    }

    function withdraw(address payable to) external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "no funds");
        to.transfer(bal);
        emit Withdraw(to, bal);
    }

    function fileCount(address u) external view returns (uint256) { return _files[u].length; }

    function getFile(address u, uint256 i)
        external view
        returns (string memory cid, uint256 size, uint256 ts, string memory tag)
    {
        require(i < _files[u].length, "index oob");
        File storage f = _files[u][i];
        return (f.cid, f.size, f.ts, f.tag);
    }
}
