// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title CurrencyCrisisToken
/// @notice A rebasable ERC20 token that simulates a currency crisis by adjusting a global scaling factor.
/// Balances are stored as "raw" amounts and effective balances are computed as:
///     effectiveBalance = rawBalance * scalingFactor / 1e18.
/// The owner can mint, burn, and trigger a crisis event (reduce scaling factor) which devalues all token balances.
contract CurrencyCrisisToken is Ownable, ReentrancyGuard {
    string public name = "Currency Crisis Token";
    string public symbol = "CCT";
    uint8 public decimals = 18;

    // Global scaling factor (with 1e18 precision). Effective balance = rawBalance * scalingFactor / 1e18.
    uint256 public scalingFactor = 1e18;

    // Total raw supply is the sum of all raw balances.
    uint256 public totalRawSupply;

    // Mapping from addresses to their raw balances.
    mapping(address => uint256) private rawBalances;
    // Allowance mapping.
    mapping(address => mapping(address => uint256)) private _allowances;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Rebase(uint256 oldScalingFactor, uint256 newScalingFactor);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    /// @notice Constructor that mints an initial supply (in effective units) to the deployer.
    /// @param initialSupply The initial effective supply.
    constructor(uint256 initialSupply) Ownable(msg.sender) {
        // For initial supply, raw supply equals effective supply when scalingFactor is 1e18.
        totalRawSupply = initialSupply;
        rawBalances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    /// @notice Returns the effective balance of an account.
    function balanceOf(address account) public view returns (uint256) {
        return (rawBalances[account] * scalingFactor) / 1e18;
    }

    /// @notice Returns the total effective supply.
    function totalSupply() public view returns (uint256) {
        return (totalRawSupply * scalingFactor) / 1e18;
    }

    /// @notice Transfers tokens from the caller to a recipient.
    /// @param to The recipient address.
    /// @param amount The amount in effective units.
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Transfer to zero address");
        uint256 rawAmount = (amount * 1e18) / scalingFactor;
        require(rawBalances[msg.sender] >= rawAmount, "Insufficient balance");

        rawBalances[msg.sender] -= rawAmount;
        rawBalances[to] += rawAmount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Approves a spender to transfer tokens on behalf of the caller.
    /// @param spender The address allowed to spend.
    /// @param amount The effective amount allowed.
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Returns the effective allowance for a spender.
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice Transfers tokens on behalf of the owner using an allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        require(allowed >= amount, "Allowance exceeded");
        uint256 rawAmount = (amount * 1e18) / scalingFactor;
        require(rawBalances[from] >= rawAmount, "Insufficient balance");

        rawBalances[from] -= rawAmount;
        rawBalances[to] += rawAmount;
        _allowances[from][msg.sender] = allowed - amount;
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Mints new tokens (in effective units) to a specified address.
    /// Only the owner can mint tokens.
    /// @param to The recipient address.
    /// @param amount The effective amount to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        uint256 rawAmount = (amount * 1e18) / scalingFactor;
        totalRawSupply += rawAmount;
        rawBalances[to] += rawAmount;
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /// @notice Burns tokens (in effective units) from a specified address.
    /// Only the owner can burn tokens.
    /// @param from The address from which tokens will be burned.
    /// @param amount The effective amount to burn.
    function burn(address from, uint256 amount) external onlyOwner {
        require(from != address(0), "Cannot burn from zero address");
        uint256 rawAmount = (amount * 1e18) / scalingFactor;
        require(rawBalances[from] >= rawAmount, "Insufficient balance");
        rawBalances[from] -= rawAmount;
        totalRawSupply -= rawAmount;
        emit Burn(from, amount);
        emit Transfer(from, address(0), amount);
    }

    /// @notice Triggers a crisis event by reducing the scaling factor.
    /// This function devalues all token balances by reducing the effective balance.
    /// @param newScalingFactor The new scaling factor, which must be lower than the current factor.
    function triggerCrisis(uint256 newScalingFactor) external onlyOwner nonReentrant {
        require(newScalingFactor < scalingFactor, "New scaling factor must be lower");
        uint256 oldScalingFactor = scalingFactor;
        scalingFactor = newScalingFactor;
        emit Rebase(oldScalingFactor, newScalingFactor);
    }

    /// @notice Fallback function to receive Ether.
    receive() external payable {}
}
