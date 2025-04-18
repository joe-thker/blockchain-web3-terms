// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AdminDrivenGovernance
 * @notice Simplest pattern: owner executes proposals when off‑chain consensus is reached.
 */
contract AdminDrivenGovernance is Ownable {
    mapping(uint256 => bool) public executed;

    event ProposalExecuted(uint256 indexed proposalId, address indexed target, bytes data);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Execute a proposal. Off‑chain you must have reached consensus before.
     * @param proposalId Unique ID.
     * @param target     Address to call.
     * @param data       Calldata for the call.
     */
    function executeProposal(
        uint256 proposalId,
        address target,
        bytes calldata data
    ) external onlyOwner {
        require(!executed[proposalId], "Already executed");
        executed[proposalId] = true;

        (bool ok, ) = target.call(data);
        require(ok, "Call failed");

        emit ProposalExecuted(proposalId, target, data);
    }
}
