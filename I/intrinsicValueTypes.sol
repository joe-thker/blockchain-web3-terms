// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Intrinsic Value Types
/// @notice Demonstrates different types of intrinsic value for crypto tokens

/// 1. Staking Reward-Based Value
contract StakingIntrinsicValue is ERC20, Ownable {
    uint256 public totalStakedETH;

    constructor() ERC20("Staking Token", "STK") Ownable(msg.sender) {}

    receive() external payable {
        totalStakedETH += msg.value;
    }

    function intrinsicValuePerToken() external view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return totalStakedETH / totalSupply();
    }
}

/// 2. Revenue Share-Based Value
contract FeeShareToken is ERC20, Ownable {
    uint256 public totalFees;

    constructor() ERC20("Fee Share Token", "FST") Ownable(msg.sender) {}

    receive() external payable {
        totalFees += msg.value;
    }

    function claimableValue(address user) public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return (totalFees * balanceOf(user)) / totalSupply();
    }
}

/// 3. Stable Asset-Backed Value
contract CollateralBackedStablecoin is ERC20, Ownable {
    uint256 public totalCollateral;

    constructor() ERC20("Stable USD", "sUSD") Ownable(msg.sender) {}

    receive() external payable {
        totalCollateral += msg.value;
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }

    function backingPerToken() external view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return totalCollateral / totalSupply();
    }
}

/// 4. Utility-Based Value (Burn for Feature Access)
contract UtilityToken is ERC20, Ownable {
    constructor() ERC20("Utility Token", "UTIL") Ownable(msg.sender) {}

    function useFeature() external {
        _burn(msg.sender, 1e18); // burn 1 UTIL token to use feature
    }
}

/// 5. Governance-Based Value (Voting Rights)
contract GovernanceToken is ERC20, Ownable {
    mapping(address => uint256) public votingWeight;

    constructor() ERC20("Governance Token", "GOV") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        votingWeight[to] += amount;
    }

    function vote() external view returns (uint256 weight) {
        return votingWeight[msg.sender];
    }
}
