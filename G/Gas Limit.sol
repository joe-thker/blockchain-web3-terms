// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasLimitTracker {
    event GasLimitReceived(uint256 gasLimit);

    function trackGasLimit() external {
        uint256 gasLimit = gasleft();
        emit GasLimitReceived(gasLimit);
    }
}
