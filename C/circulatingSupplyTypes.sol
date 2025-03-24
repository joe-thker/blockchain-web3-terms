// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CirculatingSupplyTokenExtended
/// @notice An ERC20 token that tracks total supply, circulating supply (free tokens), and fully diluted supply.
/// The owner can lock tokens to remove them from circulation (e.g., for team reserves or vesting), and the maximum supply is fixed.
contract CirculatingSupplyTokenExtended is ERC20, Ownable {
    // The maximum number of tokens that can ever exist.
    uint256 public immutable maxSupply;
    
    // Mapping to track locked token balances for each account.
    mapping(address => uint256) public lockedBalances;
    // Total tokens that are locked (non-circulating).
    uint256 public lockedTotal;

    event TokensLocked(address indexed account, uint256 amount);
    event TokensUnlocked(address indexed account, uint256 amount);

    /// @notice Constructor mints an initial supply and sets the maximum supply.
    /// @param _initialSupply The number of tokens to mint initially.
    /// @param _maxSupply The maximum token supply.
    constructor(uint256 _initialSupply, uint256 _maxSupply)
        ERC20("CirculatingSupplyTokenExtended", "CSTE")
        Ownable(msg.sender)
    {
        require(_initialSupply <= _maxSupply, "Initial supply must be <= max supply");
        maxSupply = _maxSupply;
        _mint(msg.sender, _initialSupply);
    }

    /// @notice Allows the owner to mint additional tokens if maxSupply is not exceeded.
    /// @param to The address to receive minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }

    /// @notice Locks tokens from an account, reducing circulating supply.
    /// @param account The address whose tokens will be locked.
    /// @param amount The number of tokens to lock.
    function lockTokens(address account, uint256 amount) external onlyOwner {
        require(balanceOf(account) >= amount, "Insufficient balance to lock");
        lockedBalances[account] += amount;
        lockedTotal += amount;
        emit TokensLocked(account, amount);
    }

    /// @notice Unlocks tokens from an account, returning them to circulation.
    /// @param account The address whose tokens will be unlocked.
    /// @param amount The number of tokens to unlock.
    function unlockTokens(address account, uint256 amount) external onlyOwner {
        require(lockedBalances[account] >= amount, "Insufficient locked balance");
        lockedBalances[account] -= amount;
        lockedTotal -= amount;
        emit TokensUnlocked(account, amount);
    }

    /// @notice Returns the circulating supply (i.e., total supply minus locked tokens).
    /// @return The circulating supply.
    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - lockedTotal;
    }

    /// @notice Returns the non-circulating supply (i.e., tokens that are locked).
    /// @return The locked token amount.
    function nonCirculatingSupply() external view returns (uint256) {
        return lockedTotal;
    }

    /// @notice Returns the fully diluted supply (i.e., maximum token supply).
    /// @return The fully diluted supply.
    function fullyDilutedSupply() external view returns (uint256) {
        return maxSupply;
    }
}
