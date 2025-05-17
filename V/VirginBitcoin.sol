// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VirginToken - Track tokens that have never been transferred
contract VirginToken {
    string public name = "VirginBTC";
    string public symbol = "vBTC";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public hasTransferred;
    mapping(address => bool) public isVirgin;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event VirginClaimed(address indexed user);

    constructor() {
        _mint(msg.sender, 1_000_000 ether);
    }

    function _mint(address to, uint256 amount) internal {
        balanceOf[to] += amount;
        totalSupply += amount;
        isVirgin[to] = true;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        // Mark sender as non-virgin
        if (!hasTransferred[msg.sender]) {
            hasTransferred[msg.sender] = true;
            isVirgin[msg.sender] = false;
        }

        // Receiver inherits non-virgin status
        isVirgin[to] = false;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function claimVirginStatus() external view returns (bool) {
        return isVirgin[msg.sender] && balanceOf[msg.sender] > 0 && !hasTransferred[msg.sender];
    }

    function isVirginAddress(address user) external view returns (bool) {
        return isVirgin[user];
    }
}
