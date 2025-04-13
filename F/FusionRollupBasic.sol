// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IZKVerifier {
    function verify(bytes calldata proof, bytes32 expectedRoot) external view returns (bool);
}

contract FusionRollupZK {
    address public operator;
    IZKVerifier public zkVerifier;

    struct ZKBatch {
        bytes32 dataRoot;
        bool finalized;
    }

    mapping(uint256 => ZKBatch) public batches;
    uint256 public batchCounter;

    event ZKBatchSubmitted(uint256 indexed id, bytes32 root);

    constructor(address _operator, address _verifier) {
        operator = _operator;
        zkVerifier = IZKVerifier(_verifier);
    }

    function submitZKBatch(bytes32 root, bytes calldata proof) external {
        require(msg.sender == operator, "Not operator");
        require(zkVerifier.verify(proof, root), "Invalid ZK proof");

        batches[++batchCounter] = ZKBatch(root, true);
        emit ZKBatchSubmitted(batchCounter, root);
    }
}
