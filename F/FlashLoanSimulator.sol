// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FlashLoanSimulator {
    event Simulated(uint256 fakeLoanAmount);

    function simulateLoan(uint256 fakeAmount) external {
        emit Simulated(fakeAmount);
    }
}
