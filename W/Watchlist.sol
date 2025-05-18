// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WatchlistRegistry {
    address public immutable admin;
    mapping(address => bool) public isWatchlisted;
    event Watchlisted(address indexed target, string reason);
    event Unwatchlisted(address indexed target);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function addToWatchlist(address target, string calldata reason) external onlyAdmin {
        isWatchlisted[target] = true;
        emit Watchlisted(target, reason);
    }

    function removeFromWatchlist(address target) external onlyAdmin {
        isWatchlisted[target] = false;
        emit Unwatchlisted(target);
    }

    function isListed(address addr) external view returns (bool) {
        return isWatchlisted[addr];
    }
}
