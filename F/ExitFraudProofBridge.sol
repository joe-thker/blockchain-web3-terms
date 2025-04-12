// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ExitFraudProofBridge {
    mapping(bytes32 => bool) public processedExits;

    event ExitProcessed(address user, uint256 amount);
    event FraudDetected(bytes32 exitHash, address challenger);

    function processExit(address user, uint256 amount, bytes calldata proof) external {
        bytes32 exitHash = keccak256(abi.encode(user, amount, proof));
        require(!processedExits[exitHash], "Exit already processed");

        if (!isValidProof(proof)) {
            emit FraudDetected(exitHash, msg.sender);
            return;
        }

        processedExits[exitHash] = true;
        payable(user).transfer(amount);
        emit ExitProcessed(user, amount);
    }

    function isValidProof(bytes calldata proof) internal pure returns (bool) {
        return proof.length > 0; // mock check; replace with Merkle/zk
    }

    receive() external payable {}
}
