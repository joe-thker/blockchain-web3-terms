// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CommitRevealHiddenCap {
    address public owner;
    bytes32 public commitHash;
    uint256 public revealedCap;
    bool public capRevealed;

    uint256 public totalRaised;

    constructor(bytes32 _commitHash) {
        owner = msg.sender;
        commitHash = _commitHash;
    }

    receive() external payable {
        require(!capRevealed || totalRaised + msg.value <= revealedCap, "Cap exceeded");
        totalRaised += msg.value;
    }

    function revealCap(string memory secret, uint256 cap) external {
        require(msg.sender == owner, "Not owner");
        require(!capRevealed, "Already revealed");
        require(keccak256(abi.encodePacked(secret, cap)) == commitHash, "Reveal invalid");

        revealedCap = cap;
        capRevealed = true;
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}
