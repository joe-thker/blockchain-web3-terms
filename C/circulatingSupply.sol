// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CirculatingSupplyToken
/// @notice An ERC20 token that tracks circulating supply by allowing the owner to lock tokens,
/// removing them from circulation. Circulating supply is computed as total supply minus locked tokens.
contract CirculatingSupplyToken is ERC20, Ownable {
    // Mapping to track locked balances per account.
    mapping(address => uint256) public lockedBalances;
    // Total locked tokens in the contract.
    uint256 public lockedTotal;

    event TokensLocked(address indexed account, uint256 amount);
    event TokensUnlocked(address indexed account, uint256 amount);

    /// @notice Constructor initializes the token with a name, symbol, and mints an initial supply to the deployer.
    /// @param initialSupply The total initial supply (in the smallest unit, e.g., wei for tokens with 18 decimals).
    constructor(uint256 initialSupply) ERC20("CirculatingSupplyToken", "CST") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
    
    /// @notice Locks tokens from a specified account, reducing circulating supply.
    /// @dev Only the owner can lock tokens. This could be used to lock team tokens, reserve funds, etc.
    /// @param account The address whose tokens will be locked.
    /// @param amount The number of tokens to lock.
    function lockTokens(address account, uint256 amount) external onlyOwner {
        require(balanceOf(account) >= amount, "Insufficient balance to lock");
        lockedBalances[account] += amount;
        lockedTotal += amount;
        emit TokensLocked(account, amount);
    }
    
    /// @notice Unlocks tokens from a specified account, returning them to circulation.
    /// @dev Only the owner can unlock tokens.
    /// @param account The address whose tokens will be unlocked.
    /// @param amount The number of tokens to unlock.
    function unlockTokens(address account, uint256 amount) external onlyOwner {
        require(lockedBalances[account] >= amount, "Insufficient locked balance");
        lockedBalances[account] -= amount;
        lockedTotal -= amount;
        emit TokensUnlocked(account, amount);
    }
    
    /// @notice Returns the circulating supply.
    /// @return The circulating supply, computed as total supply minus locked tokens.
    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - lockedTotal;
    }
}
