// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GovernanceFork {
    uint256 public yesVotes;
    uint256 public noVotes;
    bool public forkPassed;
    mapping(address => bool) public voted;

    function vote(bool supportFork) external {
        require(!voted[msg.sender], "Already voted");
        voted[msg.sender] = true;

        if (supportFork) {
            yesVotes++;
        } else {
            noVotes++;
        }

        if (yesVotes >= 100) {
            forkPassed = true;
        }
    }

    function status() public view returns (string memory) {
        if (forkPassed) return "Fork will be executed.";
        return "No consensus yet.";
    }
}
