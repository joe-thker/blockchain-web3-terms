// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WeiPayVault - Accepts ETH in Wei, tracks deposits, and enables withdrawals
contract WeiPayVault {
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 weiAmount);
    event Withdrawn(address indexed user, uint256 weiAmount);

    /// @notice Accept ETH and track in Wei
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw stored ETH (in Wei)
    function withdraw(uint256 amountWei) external {
        require(balances[msg.sender] >= amountWei, "Insufficient");
        balances[msg.sender] -= amountWei;
        (bool ok, ) = msg.sender.call{value: amountWei}("");
        require(ok, "Transfer failed");
        emit Withdrawn(msg.sender, amountWei);
    }

    /// @notice Return balance in ETH (for frontend display)
    function balanceInEth(address user) external view returns (uint256) {
        return balances[user] / 1e18;
    }

    /// @notice Return balance in Gwei
    function balanceInGwei(address user) external view returns (uint256) {
        return balances[user] / 1e9;
    }
}
