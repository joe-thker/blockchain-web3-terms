// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

///////////////////////////////////////////////////////////////////////////
// 1) Miner Collateral Stake
///////////////////////////////////////////////////////////////////////////
contract MinerStake {
    mapping(address => uint256) public stake;
    mapping(address => uint256) public unlockTime;
    uint256 public lockPeriod = 1 days;
    uint256 public minStake = 1 ether;

    // --- Attack: miner stakes then immediately withdraws
    function withdrawInsecure(uint256 amount) external {
        require(stake[msg.sender] >= amount, "Insufficient stake");
        // no lock or slashing
        stake[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // --- Defense: enforce minStake, lockPeriod, and slash on misbehavior
    function withdrawSecure(uint256 amount) external {
        require(stake[msg.sender] - amount >= minStake, "Below minStake");
        require(block.timestamp >= unlockTime[msg.sender], "Still locked");
        stake[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function stakeCollateral() external payable {
        require(msg.value >= minStake, "Stake too low");
        stake[msg.sender] += msg.value;
        unlockTime[msg.sender] = block.timestamp + lockPeriod;
    }

    // Owner can slash misbehaving miner
    address public owner = msg.sender;
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    function slash(address miner, uint256 amount) external onlyOwner {
        require(stake[miner] >= amount, "Insufficient stake");
        stake[miner] -= amount;
        // slashed funds go to contract owner
        payable(owner).transfer(amount);
    }
}

///////////////////////////////////////////////////////////////////////////
// 2) Proof Submission
///////////////////////////////////////////////////////////////////////////
interface IProofVerifier {
    function verify(bytes calldata proof, uint256 challengeId) external view returns (bool);
}

contract Proofs is ReentrancyGuard {
    IProofVerifier public verifier;
    mapping(bytes32 => bool) public seenProof; // miner|challenge

    constructor(address _verifier) {
        verifier = IProofVerifier(_verifier);
    }

    // --- Attack: accept any proof without verification or replay guard
    function submitProofInsecure(bytes calldata proof, uint256 challengeId) external {
        // no verification, no replay guard
        // reward logic omitted
    }

    // --- Defense: verify proof + prevent replay
    function submitProofSecure(bytes calldata proof, uint256 challengeId) external nonReentrant {
        require(verifier.verify(proof, challengeId), "Invalid proof");
        bytes32 key = keccak256(abi.encodePacked(msg.sender, challengeId));
        require(!seenProof[key], "Proof already submitted");
        seenProof[key] = true;
        // reward logic omitted
    }
}

///////////////////////////////////////////////////////////////////////////
// 3) Reward Claiming
///////////////////////////////////////////////////////////////////////////
contract RewardClaim is ReentrancyGuard {
    mapping(address => mapping(uint256 => bool)) public claimed;
    uint256 public rewardPerEpoch = 1 ether;

    // --- Attack: miners call twice per epoch
    function claimInsecure(uint256 epoch) external {
        // no check of claimed
        payable(msg.sender).transfer(rewardPerEpoch);
    }

    // --- Defense: record and prevent double-claim + nonReentrant
    function claimSecure(uint256 epoch) external nonReentrant {
        require(!claimed[msg.sender][epoch], "Already claimed");
        claimed[msg.sender][epoch] = true;
        payable(msg.sender).transfer(rewardPerEpoch);
    }

    // fund rewards
    receive() external payable {}
}
