// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

///////////////////////////////////////////////////////////////////////////
// 1) Node Registration & Stake
///////////////////////////////////////////////////////////////////////////
contract NodeRegistry {
    uint256 public minStake = 1 ether;
    uint256 public lockPeriod = 1 days;

    struct Node { uint256 stake; uint256 unlockTime; bool registered; }
    mapping(address => Node) public nodes;

    // --- Attack: anyone registers with zero stake
    function registerInsecure() external {
        nodes[msg.sender].registered = true;
    }

    // --- Defense: require stake deposit, unique, lockPeriod
    function registerSecure() external payable {
        require(!nodes[msg.sender].registered, "Already registered");
        require(msg.value >= minStake, "Insufficient stake");
        nodes[msg.sender] = Node({
            stake: msg.value,
            unlockTime: block.timestamp + lockPeriod,
            registered: true
        });
    }

    // --- Attack: instant deregistration, even before anyone relies on node
    function deregisterInsecure() external {
        require(nodes[msg.sender].registered, "Not registered");
        nodes[msg.sender].registered = false;
        payable(msg.sender).transfer(nodes[msg.sender].stake);
        nodes[msg.sender].stake = 0;
    }

    // --- Defense: enforce lockPeriod before deregistration
    function deregisterSecure() external {
        Node storage n = nodes[msg.sender];
        require(n.registered, "Not registered");
        require(block.timestamp >= n.unlockTime, "Stake locked");
        n.registered = false;
        uint256 amt = n.stake;
        n.stake = 0;
        payable(msg.sender).transfer(amt);
    }
}

///////////////////////////////////////////////////////////////////////////
// 2) Data Availability Proof
///////////////////////////////////////////////////////////////////////////
interface IProofVerifier {
    function verify(bytes calldata proof, uint256 dataId) external view returns (bool);
}

contract DataProof is ReentrancyGuard {
    IProofVerifier public verifier;
    mapping(bytes32 => bool) public seen; // keccak(node,dataId)

    constructor(address _verifier) {
        verifier = IProofVerifier(_verifier);
    }

    // --- Attack: accept any proof, no replay guard
    function submitProofInsecure(bytes calldata proof, uint256 dataId) external {
        // no check, rewards would be paid here
    }

    // --- Defense: verify proof + prevent replay
    function submitProofSecure(bytes calldata proof, uint256 dataId) external nonReentrant {
        require(verifier.verify(proof, dataId), "Invalid proof");
        bytes32 key = keccak256(abi.encodePacked(msg.sender, dataId));
        require(!seen[key], "Proof already submitted");
        seen[key] = true;
        // issue reward...
    }
}

///////////////////////////////////////////////////////////////////////////
// 3) Service Payment Settlement
///////////////////////////////////////////////////////////////////////////
contract Payouts is ReentrancyGuard {
    mapping(address => uint256) public earned;

    // Called by off-chain system to top up node earnings
    function creditInsecure(address node, uint256 amount) external {
        // no auth, anyone can credit anyone
        earned[node] += amount;
    }

    function creditSecure(address node, uint256 amount) external {
        // replace with proper access control (e.g., onlyOwner or onlyVerifier)
        require(msg.sender == address(this), "Unauthorized"); 
        earned[node] += amount;
    }

    // --- Attack: withdraw multiple times, no accounting
    function withdrawInsecure() external {
        payable(msg.sender).transfer(earned[msg.sender]);
    }

    // --- Defense: CEI + zero out + nonReentrant
    function withdrawSecure() external nonReentrant {
        uint256 amt = earned[msg.sender];
        require(amt > 0, "Nothing to withdraw");
        earned[msg.sender] = 0;               // Effects
        payable(msg.sender).transfer(amt);    // Interaction
    }

    // fund contract
    receive() external payable {}
}
