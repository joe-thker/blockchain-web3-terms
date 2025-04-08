// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FlashLoanWithETH {
    receive() external payable {}

    function executeFlashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Insufficient ETH");

        payable(msg.sender).transfer(amount);

        IFlashLoanETHBorrower(msg.sender).executeOnFlashLoan{value: amount}(amount);

        require(address(this).balance >= balanceBefore, "ETH not repaid");
    }
}

interface IFlashLoanETHBorrower {
    function executeOnFlashLoan(uint256 amount) external payable;
}
