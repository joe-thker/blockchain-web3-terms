// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title InternalTransactionExample
/// @notice Shows how internal calls trigger events and logic
contract InternalTransactionExample {
    event ActionCalled(address indexed from, uint256 value);
    event InternalTransfer(address from, address to, uint256 value);

    /// @notice Public entrypoint that calls an internal function
    function performAction(address to) external payable {
        require(msg.value > 0, "Send ETH");
        emit ActionCalled(msg.sender, msg.value);
        _internalTransfer(to, msg.value);
    }

    /// @dev This is an internal transaction — not directly visible as a tx
    function _internalTransfer(address recipient, uint256 amount) internal {
        payable(recipient).transfer(amount);
        emit InternalTransfer(address(this), recipient, amount);
    }

    // Allow receiving ETH for testing
    receive() external payable {}
}
