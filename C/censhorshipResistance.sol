// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CensorshipControl
/// @notice This contract implements a basic censorship mechanism by maintaining a blacklist of addresses.
/// Only addresses not on the blacklist can perform certain actions (e.g., post messages).
contract CensorshipControl {
    address public owner;
    mapping(address => bool) public blacklist;

    event Blacklisted(address indexed addr);
    event RemovedFromBlacklist(address indexed addr);
    event MessagePosted(address indexed sender, string message);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "Address is blacklisted");
        _;
    }

    /// @notice Constructor sets the deployer as the contract owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Adds an address to the blacklist. Only the owner can call this function.
    /// @param _addr The address to blacklist.
    function addToBlacklist(address _addr) external onlyOwner {
        blacklist[_addr] = true;
        emit Blacklisted(_addr);
    }

    /// @notice Removes an address from the blacklist. Only the owner can call this function.
    /// @param _addr The address to remove from the blacklist.
    function removeFromBlacklist(address _addr) external onlyOwner {
        blacklist[_addr] = false;
        emit RemovedFromBlacklist(_addr);
    }

    /// @notice Allows non-blacklisted users to post a message.
    /// @param _message The message content.
    function postMessage(string calldata _message) external notBlacklisted {
        emit MessagePosted(msg.sender, _message);
    }
}
