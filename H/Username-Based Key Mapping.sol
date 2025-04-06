// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UsernameKeyRegistry {
    mapping(string => address) public usernames;

    function register(string calldata username) external {
        require(usernames[username] == address(0), "Taken");
        usernames[username] = msg.sender;
    }

    function getAddress(string calldata username) external view returns (address) {
        return usernames[username];
    }
}
