// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ForkConsensusMeter {
    uint256 public forFork;
    uint256 public againstFork;
    mapping(address => bool) public hasVoted;

    function supportFork() external {
        require(!hasVoted[msg.sender], "Voted");
        hasVoted[msg.sender] = true;
        forFork++;
    }

    function opposeFork() external {
        require(!hasVoted[msg.sender], "Voted");
        hasVoted[msg.sender] = true;
        againstFork++;
    }

    function viewMajority() external view returns (string memory) {
        if (forFork > againstFork) return "Majority support for fork";
        if (againstFork > forFork) return "Majority oppose fork";
        return "Undecided";
    }
}
