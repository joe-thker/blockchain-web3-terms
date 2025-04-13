// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FusionRollupBridge {
    address public operator;
    mapping(address => uint256) public balances;

    event WithdrawPrepared(address indexed user, uint256 amount, uint256 batchId);
    event WithdrawalFinalized(address indexed user, uint256 amount);

    struct ExitRequest {
        uint256 amount;
        uint256 batchId;
        bool executed;
    }

    mapping(address => ExitRequest) public withdrawals;

    function prepareWithdraw(uint256 amount, uint256 batchId) external {
        withdrawals[msg.sender] = ExitRequest(amount, batchId, false);
        emit WithdrawPrepared(msg.sender, amount, batchId);
    }

    function finalizeWithdraw(address user) external {
        ExitRequest storage req = withdrawals[user];
        require(!req.executed, "Already executed");
        req.executed = true;
        balances[user] += req.amount;
        emit WithdrawalFinalized(user, req.amount);
    }
}
