// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title UPoWSimulator - Accepts submissions of useful off-chain work (e.g., scientific results)
contract UPoWSimulator {
    address public verifier; // off-chain oracle / verifier service
    mapping(bytes32 => bool) public acceptedProofs;
    mapping(address => uint256) public rewards;

    event ProofSubmitted(address indexed user, bytes32 proofHash);
    event ProofAccepted(address indexed user, uint256 reward);

    modifier onlyVerifier() {
        require(msg.sender == verifier, "Not verifier");
        _;
    }

    constructor(address _verifier) {
        verifier = _verifier;
    }

    /// @notice Submit hash of useful work result (off-chain verification pending)
    function submitProof(bytes32 proofHash) external {
        emit ProofSubmitted(msg.sender, proofHash);
    }

    /// @notice Verifier confirms proof and assigns reward
    function acceptProof(address worker, bytes32 proofHash, uint256 reward) external onlyVerifier {
        require(!acceptedProofs[proofHash], "Already accepted");
        acceptedProofs[proofHash] = true;
        rewards[worker] += reward;
        emit ProofAccepted(worker, reward);
    }

    function withdrawRewards() external {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}
