// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Layer-1 Finality Tracker
/// @notice Simulates validator-based block finalization (abstracted L1 logic)
contract Layer1Finality {
    address public admin;
    uint256 public blockId;
    mapping(uint256 => bytes32) public finalizedBlockHashes;
    mapping(address => bool) public validators;

    event BlockFinalized(uint256 indexed blockId, bytes32 blockHash);

    modifier onlyValidator() {
        require(validators[msg.sender], "Not a validator");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function addValidator(address _validator) external {
        require(msg.sender == admin, "Only admin");
        validators[_validator] = true;
    }

    function finalizeBlock(bytes32 _blockHash) external onlyValidator {
        finalizedBlockHashes[blockId] = _blockHash;
        emit BlockFinalized(blockId, _blockHash);
        blockId++;
    }

    function getFinalizedBlock(uint256 _id) external view returns (bytes32) {
        return finalizedBlockHashes[_id];
    }
}
