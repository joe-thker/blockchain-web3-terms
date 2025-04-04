pragma solidity ^0.8.20;

contract GameGenesis {
    mapping(address => uint256) public xp;
    mapping(address => bool) public registered;

    constructor(address[] memory players) {
        for (uint256 i = 0; i < players.length; i++) {
            xp[players[i]] = 100; // Genesis players start with 100 XP
            registered[players[i]] = true;
        }
    }
}
