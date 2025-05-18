// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ZeroConfProtectedBridge - Only accepts txs confirmed via offchain validator/oracle
contract ZeroConfProtectedBridge {
    address public oracle;
    mapping(bytes32 => bool) public processed;

    event DepositProcessed(bytes32 txHash, address user, uint256 amount);

    constructor(address _oracle) {
        oracle = _oracle;
    }

    /// @notice Called by trusted oracle after tx has ≥1 confirmation
    function processConfirmedDeposit(bytes32 txHash, address user, uint256 amount) external {
        require(msg.sender == oracle, "Not authorized");
        require(!processed[txHash], "Already processed");
        processed[txHash] = true;

        // E.g., mint a token or bridge funds
        emit DepositProcessed(txHash, user, amount);
    }
}
