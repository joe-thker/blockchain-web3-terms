// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title WhaleGuardedToken - ERC20 with anti-whale transfer cap and alerting
contract WhaleGuardedToken is ERC20 {
    uint256 public immutable maxTxPercent; // e.g., 1% = 1e16 (out of 1e18)
    uint256 public immutable launchTime;

    event WhaleTransferBlocked(address indexed from, address indexed to, uint256 amount);
    event WhaleTransferAlert(address indexed from, address indexed to, uint256 amount);

    constructor(uint256 _maxTxPercent) ERC20("WhaleGuardedToken", "WGT") {
        require(_maxTxPercent <= 1e18, "Invalid max");
        maxTxPercent = _maxTxPercent;
        launchTime = block.timestamp;

        _mint(msg.sender, 1_000_000 ether); // Mint 1M tokens
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from != address(0) && to != address(0)) {
            uint256 maxAllowed = (totalSupply() * maxTxPercent) / 1e18;
            if (amount > maxAllowed) {
                emit WhaleTransferBlocked(from, to, amount);
                revert("Anti-whale: transfer exceeds limit");
            }
            if (amount >= maxAllowed / 2) {
                emit WhaleTransferAlert(from, to, amount);
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
