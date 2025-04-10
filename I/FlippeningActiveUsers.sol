// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUserFeed {
    function activeUsers(address token) external view returns (uint256);
}

contract FlippeningActiveUsers {
    address public t1;
    address public t2;
    IUserFeed public feed;

    constructor(address _t1, address _t2, address _feed) {
        t1 = _t1;
        t2 = _t2;
        feed = IUserFeed(_feed);
    }

    function flipped() external view returns (bool) {
        return feed.activeUsers(t1) > feed.activeUsers(t2);
    }
}
