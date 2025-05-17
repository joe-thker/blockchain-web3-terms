// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MiniWasabiMixer {
    uint256 public constant DENOMINATION = 1 ether;

    mapping(bytes32 => bool) public nullifiers;
    mapping(bytes32 => bool) public commitments;
    address public immutable verifier;

    event Deposit(bytes32 commitment);
    event Withdrawal(address indexed to, bytes32 nullifier);

    constructor(address _verifier) {
        verifier = _verifier;
    }

    function deposit(bytes32 commitment) external payable {
        require(msg.value == DENOMINATION, "Wrong amount");
        require(!commitments[commitment], "Commitment used");

        commitments[commitment] = true;
        emit Deposit(commitment);
    }

    /// @notice Zero-knowledge proof input: nullifier, recipient, zkProof
    function withdraw(
        bytes32 nullifierHash,
        address recipient,
        bytes calldata zkProof
    ) external {
        require(!nullifiers[nullifierHash], "Already withdrawn");

        // Mocked zk verification
        require(_verifyProof(nullifierHash, recipient, zkProof), "Invalid proof");

        nullifiers[nullifierHash] = true;
        (bool ok, ) = recipient.call{value: DENOMINATION}("");
        require(ok, "ETH transfer failed");

        emit Withdrawal(recipient, nullifierHash);
    }

    function _verifyProof(
        bytes32 nullifier,
        address recipient,
        bytes calldata proof
    ) internal view returns (bool) {
        // In real usage: call external verifier contract (e.g., Groth16)
        return uint256(nullifier) % 2 == 1; // Dummy condition for simulation
    }

    receive() external payable {}
}
